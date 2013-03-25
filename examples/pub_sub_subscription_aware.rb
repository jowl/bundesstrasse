# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'thread'
require 'set'
require 'bundesstrasse'


# This example demonstrates how a publisher can detect when there are
# subscribers listening. When sending complex messages you may want to avoid
# expensive serialization of messages unless there actually is anyone listening
# for them. One way this can be achieved is through the use of an xpub socket
# in place of a regular pub socket.

# This class is an abstraction on top of an xpub socket and exposes the 
# currently subscribed to topics, so that producers can determine whether or not
# it is worth it to publish messages.
class SubscriberAwarePublisher
  attr_reader :subscriptions

  def initialize(context, bind_address)
    # We're using an xpub socket, unlike regular pub sockets you can get some
    # information about subscribers from them
    @pub_socket = context.socket(Bundesstrasse::XPubSocket)
    @pub_socket.bind(bind_address)
    @subscriptions = Set.new
  end

  def has_subscribers?
    check_subscriptions!
    @subscriptions.size > 0
  end

  def publish(topic, message)
    @pub_socket.write_multipart(topic, message)
  end

  private

  def check_subscriptions!
    loop do
      # This is the core piece of code to this example. Here we poll the xpub
      # socket for new messages about subscriptions and unsubscriptions.
      #
      # Read nonblocking until there are no more messages (signalled through a
      # Bundesstrasse::AgainError). The messages received are prefixed with a
      # zero byte for unsubscribe or a one for subscribe. The rest of the message
      # is the topic subscribed to (i.e. the prefix string given to #subscribe).
      #
      # A message will be received for the first subscription for a topic, and
      # for the last unsubscription of a topic. There is no way to count the
      # number of subscribed sockets with this method.
      #
      # To determine if we have a subscriber it would be enough to increment a
      # counter for each subscription and decrement it for each unsubscription,
      # but here we also keep track of the topics subscribed to as a set.
      message = @pub_socket.read_nonblocking
      code = message.slice!(0)
      case code.ord
      when 0
        @subscriptions.delete(message)
      when 1
        @subscriptions << message
      end
    end
  rescue Bundesstrasse::AgainError
    # this means that there were no more messages
  end
end

service_port = 4444

mutex = Mutex.new
context = Bundesstrasse::Context.create

Thread.start do
  Thread.current.abort_on_exception = true

  # This is the publisher thread, we use the SubscriberAwarePublisher 
  # abstraction defined above to keep track of when there are subscriptions, and
  # only send messages when there are. The messages include a counter so you can
  # see that the subscribers don't miss messages (a single subscriber may miss
  # a message but all messages should go to at least one subscriber). If we
  # hadn't checked for subscribers before publishing, messages sent when no
  # subscribers were connected would go missing.
  #
  # The subscriber check is not meant as a reliability feature or any kind of
  # guaranteed delivery mechanism, and the including a counter in the messages
  # is just a way of demonstrating that messages are indeed not sent when there
  # are no subscribers. There may be gaps where the subscriber sockets have
  # closed down between the publisher checking for unsubscriptions and
  # publishing the next message, but they should be rare.

  publisher = SubscriberAwarePublisher.new(context, "tcp://*:#{service_port}")

  counter = 0

  loop do
    if publisher.has_subscribers?
      publisher.publish('greetings', "Hello ##{counter}")
      counter += 1
    else
      mutex.synchronize do
        puts 'No subscribers!'
     end
    end
    sleep(1)
  end
end

3.times do
  Thread.start do
    Thread.current.abort_on_exception = true

    # This is a subscriber thread, it will connect, subscribe, read three
    # messages and then disconnect, sleep for a little while and do it over
    # again. Since we run multiple subscriber threads there can be a different
    # number of subscribers at any time, or none.

    loop do
      sub_socket = context.socket(Bundesstrasse::SubSocket)
      sub_socket.connect("tcp://localhost:#{service_port}")
      # just to complicate things, we randomly subscribe to a specific topic or
      # all topics (an empty string means all topics) -- in this example all
      # messages are sent to the topic "greetings" so either way the same
      # messages will be received
      if rand < 0.5
        sub_socket.subscribe('')
      else
        sub_socket.subscribe('greetings')
      end
      3.times do
        topic, message = sub_socket.read_multipart
        mutex.synchronize do
          puts message
        end
      end
      # you can unsubscribe manually, but that will also happen when you
      # close the socket
      # sub_socket.unsubscribe('')
      sub_socket.close!
      sleep(rand(10))
    end
  end
end

sleep