# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'thread'
require 'bundesstrasse'


# This example demonstrates pub/sub with multiple producers using a forwarder
# device. The producers connect to the forwarder using an inproc socket and
# it then exposes a pub socket over TCP. The consumer can subscribe just as
# if it was a single publisher.

frontend_port = 4444
backend_uri = 'inproc://pubsub'

context = Bundesstrasse::Context.create

device = Bundesstrasse::ForwarderDevice.create(context)
device.frontend.bind("tcp://*:#{frontend_port}")
device.backend.bind(backend_uri)

Thread.start do
  Thread.current.abort_on_exception = true
  device.start
end

4.times do |n|
  Thread.start do
    Thread.current.abort_on_exception = true

    pub_socket = context.socket(Bundesstrasse::PubSocket)
    pub_socket.connect(backend_uri)

    loop do
      pub_socket.write_multipart("hello.#{n}", "Hello from #{n}")
      sleep(rand)
    end
  end
end

Thread.start do
  Thread.current.abort_on_exception = true

  sub_socket = context.socket(Bundesstrasse::SubSocket)
  sub_socket.connect("tcp://localhost:#{frontend_port}")
  sub_socket.subscribe('hello.0')
  sub_socket.subscribe('hello.2')

  loop do
    _, message = sub_socket.read_multipart
    puts message
  end
end

sleep