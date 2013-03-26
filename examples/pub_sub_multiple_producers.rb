# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'bundesstrasse'


# This example demonstrates pub/sub with multiple producers using a forwarder
# device. The producers connect to the forwarder using an inproc socket and
# it then exposes a pub socket over TCP. The consumer can subscribe just as
# if it was a single publisher.

service_port = 4444
internal_address = 'inproc://pubsub'

context = Bundesstrasse::Context.create

# Forwarder devices look like they are set up the wrong way around, the
# "frontend" is what talk to your internal pub sockets, and the "backend"
# is facing external consumers. The meaning of "front" and "back" comes from
# the direction the messages flow. In a forwarder the messages flow; the 
# "frontend" is the part where messages come in and the "backend" where messages
# are sent out (in a queue device messages come in through the "frontend" from
# an external req socket).

device = Bundesstrasse::ForwarderDevice.create(context)
device.frontend.bind(internal_address)
device.frontend.subscribe('')
device.backend.bind("tcp://*:#{service_port}")

Thread.start do
  Thread.current.abort_on_exception = true
  device.start
end

4.times do |n|
  Thread.start do
    Thread.current.abort_on_exception = true

    # Notice that the pub socket does not #bind to the backend, but #connects.

    pub_socket = context.pub_socket
    pub_socket.connect(internal_address)

    loop do
      pub_socket.write_multipart("hello.#{n}", "Hello from #{n}")
      sleep(rand)
    end
  end
end

Thread.start do
  Thread.current.abort_on_exception = true

  # The subscriber acts like a normal subscriber, it is not aware that the
  # publisher is actually a device.

  sub_socket = context.sub_socket
  sub_socket.connect("tcp://localhost:#{service_port}")
  sub_socket.subscribe('hello.0')
  sub_socket.subscribe('hello.2')

  loop do
    _, message = sub_socket.read_multipart
    puts message
  end
end

sleep