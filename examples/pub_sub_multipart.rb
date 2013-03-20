# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'bundesstrasse'


# This example demonstrates pub/sub with filtering using multipart messages
# and Socket#subscribe. The code first creates a context, then starts three
# threads, one for the publisher, one for a subscriber that will receive all
# messages, and finally one that will only receive a subset of the messages.

mutex = Mutex.new
context = Bundesstrasse::Context.create

Thread.start do
  Thread.current.abort_on_exception = true

  greetings = {
    'french' => ['bonjour', 'salut', 'bienvenue', 'bonsoir'],
    'german' => ['guten tag', 'hallo', 'morgen', 'guten abend'],
    'spanish' => ['buenos días', 'hola', 'buenas noches'],
    'english' => ['hello', 'good morning', 'good evening']
  }

  # This is the publisher, it will pick a random greeting and publish it as a
  # multipart message with the language as first part followed by the greeting.
  # The subscribers can subscribe either to all greetings, or just to those for
  # a specific language.

  pub_socket = context.socket(Bundesstrasse::PubSocket)
  pub_socket.bind('tcp://*:3333')

  loop do
    language = greetings.keys.sample
    greeting = greetings[language].sample
    pub_socket.write_multipart(language, greeting)
    sleep(1)
  end
end

Thread.start do
  Thread.current.abort_on_exception = true

  # This subscriber socket will subscribe to all greetings. The empty string
  # given to #subscribe is a wildcard subscription.

  sub_socket = context.socket(Bundesstrasse::SubSocket)
  sub_socket.connect('tcp://localhost:3333')
  sub_socket.subscribe('')

  loop do
    greeting = sub_socket.read_multipart
    mutex.synchronize do
      puts "Multilingual greeting: #{greeting.last}"
    end
  end
end

Thread.start do
  Thread.current.abort_on_exception = true

  # This subscriber will subscribe only to greetings in french or spanish.

  sub_socket = context.socket(Bundesstrasse::SubSocket)
  sub_socket.connect('tcp://localhost:3333')
  sub_socket.subscribe('french')
  sub_socket.subscribe('spanish')

  loop do
    greeting = sub_socket.read_multipart
    mutex.synchronize do
      puts "Latin greeting: #{greeting.last}"
    end
  end
end

sleep