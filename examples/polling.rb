# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'bundesstrasse'


# This example shows simple req/res communication using the IO reactor pattern
# instead of running the client and server in separate threads and using
# blocking IO.

mutex = Mutex.new
context = Bundesstrasse::Context.create

rep_socket = context.socket(ZMQ::REP)
rep_socket.bind('inproc://poll-example')
req_socket = context.socket(ZMQ::REQ)
req_socket.connect('inproc://poll-example')

poller = ZMQ::Poller.new
poller.register(req_socket)
poller.register(rep_socket)

last_request = nil

loop do
  poller.poll
  poller.readables.each do |socket|
    case socket
    when rep_socket
      last_request = socket.read
      puts("Server received: #{last_request}")
    when req_socket
      response = socket.read
      puts("Client received: #{response}")
    end
  end
  poller.writables.each do |socket|
    case socket
    when rep_socket
      response = last_request.reverse
      puts("Server sends:    #{response}")
      socket.write(response)
    when req_socket
      request = 'foo bar'
      puts("Client sends:    #{request}")
      socket.write(request)
    end
  end
end