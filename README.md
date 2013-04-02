# Bundesstraße

[![Build Status](https://travis-ci.org/jowl/bundesstrasse.png?branch=master)](https://travis-ci.org/jowl/bundesstrasse)

A thin wrapper around [ffi-rzmq](https://github.com/chuckremes/ffi-rzmq) for JRuby, providing only basic functionality. Name inspirired by [iconara](https://github.com/iconara)'s RabbitMQ wrapper [autobahn](https://github.com/burtcorp/autobahn).

## Example usage

### Basic client/server setup

```ruby
require 'bundesstrasse'

class Client
  def initialize(context)
    @context = context
  end

  def connect!(address)
    @socket ||= @context.req_socket
    @socket.connect(address)
  end

  def send(msg)
    @socket.write(msg)
    @socket.read
  end

  def disconnect!
    @socket.close!
  end
end

class Server
  def initialize(context)
    @context = context
  end

  def start
    socket = @context.rep_socket
    socket.bind('tcp://*:5678')
    loop do
      msg = socket.read
      socket.write "Server got: #{msg}"
    end
  rescue Bundesstrasse::TermError
    # TermErrors are raised when context is terminated,
    # the socket is closed automatically
  end
end

context = Bundesstrasse::Context.create

client = Client.new(context)
client.connect!('tcp://127.0.0.1:5678')

server = Server.new(context)
server_thread = Thread.new { server.start }

puts client.send("Hello server") # prints 'Server got: Hello server'

client.disconnect!
context.terminate!

server_thread.join
```

### World's most boring chat

Client code:
```ruby
require 'bundesstrasse'

ctx = Bundesstrasse::Context.create
thread = Thread.new do
  req = ctx.socket_req
  req.connect('tcp://127.0.0.1:5678')
  puts "Welcome"
  loop do
    print "You:   "
    req.write gets.strip
    puts "Other: #{req.read}"
  end
end
Signal.trap('INT') { ctx.terminate! }
thread.join
```

Server code:
```ruby
require 'bundesstrasse'

ctx = Bundesstrasse::Context.create
thread = Thread.new do
  rep = ctx.rep_socket
  rep.connect('tcp://*:5678')
  puts "Welcome"
  loop do
    puts "Other: #{rep.read}"
    print "You:   "
    rep.write gets.strip
  end
end
Signal.trap('INT') { ctx.terminate! }
thread.join
```
