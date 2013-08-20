# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'set'
require 'bundesstrasse'


# When using a sub socket to listen for messages it can be tricky to change the
# subscriptions because the socket blocks the thread for most of the time. You
# can't subscribe to something new (i.e. call #subscribe on the socket) from 
# another thread while the socket is blocking in #read, sockets are not thread
# safe! The only window you have is when you've just received a message and 
# haven't called #read(_multipart) to wait for the next one. What if messages
# are far between, and you want to be able to start subcribing to other topics
# at any time?
#
# One way would be to use #read_nonblocking which will raise AgainError (EAGAIN)
# when there is no message immediately available. That way you'd have lots of 
# opportunity to check if it's time to subscribe to more topics. However, a
# program that does non-blocking reads over and over again is like the kids in
# the backseat asking "are we there yet" over and over. It drives people nuts,
# and it will keep your CPU busy doing nothing.
#
# A better way of doing it is using Poller. Poller is like select(2), which you
# have probably come across if you've done any socket programming. Poller keeps
# track of the state of sockets for you, blocking until any of them are
# available for reads or writes. Using a Poller means that you can act like a 
# grown up and ask the driver to tell you when you're there.
#
# However, in this case using Poller only solves half of the problem: you still
# need a way to get the new topic to subscribe to into the thread that owns the
# socket. You could use something like Ruby's Queue or a mutex and an array, but
# then you still wouldn't be able to change subscriptions quickly because Poller
# will be blocking. We've just exchanged one blocking thing for another.
#
# Don't worry, ZMQ was built to solve multithreading problems, and when in doubt
# add another socket. In this case you can use a push/pull pair as a command
# channel. The part of your code that wants to control which topics the sub
# socket is subscribed to will have a push socket which it writes commands to,
# and the thread with the sub socket will also have a pull socket that reads
# those commands. How will it read them? You add both the sub and the pull
# sockets to the Poller, and it will block until either is readable. If the sub
# socket gets a new message it will unblock and tell you, and if the pull socket
# gets a message it will also unblock and tell you. All you need to do is keep
# track of which socket the message came from so you know what to do with it.


COUNTRIES = {
  'europe' => %w[Sweden UK Germany Italia Austria Poland Ukraine Spain],
  'asia' => %w[Japan Taiwan Singapore Nepal Uzbekistan Iran Baharain],
  'africa' => %w[Zimbabwe Chad Tunisia Congo Kenya Angola Mali]
}

COUNTRIES_PUBSUB_PORT = 9876
COMMAND_ADDRESS = 'inproc://commands'

context = Bundesstrasse::Context.create

# There are a lot of sockets involved in this example, here we create them all
# up front so that it will be easier to make sure things happen in the right
# order, when you're using inproc sockets it's easy to get it wrong and #connect
# before you #bind.

pub_socket = context.socket(:pub)
pub_socket.bind("tcp://*:#{COUNTRIES_PUBSUB_PORT}")

push_socket = context.socket(:push)
push_socket.bind(COMMAND_ADDRESS)

sub_socket = context.socket(:sub)
sub_socket.connect("tcp://localhost:#{COUNTRIES_PUBSUB_PORT}")

pull_socket = context.socket(:pull)
pull_socket.connect(COMMAND_ADDRESS)

Thread.start do
  Thread.current.abort_on_exception = true

  # This is the subscriber thread. It listens for messages from the publisher
  # and to messages from the controller. The messages from the controller
  # controls which topics are subscribed and unsubscribed from. The controller
  # is stateless in this case so this thread also keeps track of which topics
  # it is currently subscribed to and ignores commands that don't make sense,
  # like subscribing to a topic it is already subscribed to, or unsubscribing
  # when it's not subscribed in the first place.
  #
  # The way the thread manages to read messages from both sockets is through
  # the use of a Poller. It registers both sockets with the Poller, telling it
  # that it wants to be told if either become readable, i.e. if there are
  # waiting messages. The Poller will block on #poll until at least one socket
  # is readable, and set its #readables property to a list of the readable
  # sockets. Then we can read messages and take action.
  #
  # When messages come in over the pull socket, the command socket, we check
  # if it's a subscribe or unsubscribe and run the corresponding method on
  # the sub socket. Since this thread is the only thread that touches the sub
  # socket this is allowed.

  poller = Bundesstrasse::Poller.new
  # Here we tell the Poller that we want to know when these sockets receive
  # messages, but we could also use #register_writable if we were instead
  # interested in them being available for writing (if we wanted to make sure
  # that we don't write if a socket's buffer is full -- that it has reached its
  # high water mark -- for example). You can also use #register without
  # arguments, which means both readable and writable.
  poller.register(sub_socket, :pollin)
  poller.register(pull_socket, :pollin)

  topics = Set.new

  loop do
    # Poller#poll blocks until the registered sockets are ready. You can give
    # #poll a timeout as well, which means that it will unblock after that time
    # even if there are no sockets available. That feature can be useful if you
    # sometimes -- a very basic example would be that you want to print a status
    # message from time to time, and messages are rare.
    readables, _ = poller.poll

    # Poller#poll returns an Poller::Accessibles object, which has a #readables
    # property, which is an array of the sockets that have waiting
    # messages. Since we want to do very different things depending on which
    # socket it is we just check each socket if it's in that array, and act if
    # it is. Notice that it's not an if-else-if case, both sockets can be
    # readable at the same time (and actually, a socket could have more than one
    # message available, but we don't handle that here -- if you run the example
    # for long enough you can actually see this in action: sometimes the text
    # "No longer listening for countries" will be printed, but then a couple of
    # countries follow before the next "Now listening for...". Just because we
    # unsubscribe does not mean that messages that had already arrived are
    # discarded -- there is a way to resolve this issue by reading all messages
    # available, but that is left as an exercise, hint: it has to do with
    # nonblocking reads).

    if readables.include?(sub_socket)
      # When the sub socket gets messages we just want to print them to stdout.
      topic, message = sub_socket.read_multipart
      puts "#{message} is a country in #{topic}"
    end

    if readables.include?(pull_socket)
      # When the command socket gets a message we check which command it is,
      # here we support two commands: subscribe and unsubscribe. In the first
      # case we call #subscribe on the sub socket (it could be that we already
      # subscribe to that topic, but there's no harm in subscribing twice). We
      # also add the topic to the set of topics so that we can print a message
      # with the current topics (which we only do if they change).
      command, topic = pull_socket.read_multipart
      topics_changed = false
      case command
      when 'subscribe'
        topics_changed = !topics.include?(topic)
        topics << topic
        sub_socket.subscribe(topic)
      when 'unsubscribe'
        topics_changed = topics.include?(topic)
        topics.delete(topic)
        sub_socket.unsubscribe(topic)
      end
      if topics_changed
        if topics.empty?
          puts '* No longer listening for countries'
        else
          puts "* Now listening for countries in #{topics.to_a.join(', ')}"
        end
      end
    end
  end
end

Thread.start do
  Thread.current.abort_on_exception = true

  # This is the publisher thread, it will publish the name of a country every
  # second, with the continent as topic. The topic is just the first part of a
  # multipart message.

  loop do
    random_continent = COUNTRIES.keys.sample
    random_country = COUNTRIES[random_continent].sample
    pub_socket.write_multipart(random_continent, random_country)
    sleep(1)
  end
end


Thread.start do
  Thread.current.abort_on_exception = true

  # This is the control thread, it simulates a user that wants to see countries
  # from different continents and clicks around in a user interface, checking
  # checkboxes and unchecking them randomly. Each "checkbox" is a subscription
  # for a continent, and checking it means subscribe, unchecking it means
  # unsubscribe.

  loop do
    random_continent = COUNTRIES.keys.sample
    command = rand < 0.5 ? 'subscribe' : 'unsubscribe'
    push_socket.write_multipart(command, random_continent)
    sleep(rand(10))
  end
end

sleep
