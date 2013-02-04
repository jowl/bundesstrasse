
# BZMQ (Basic ZeroMQ)

A thin wrapper around [ffi-rzmq](https://github.com/chuckremes/ffi-rzmq) for JRuby, providing only basic functionality.

## Example usage

    require 'bzmq'

    class Client
      def initialize
        @socket = BZMQ::ReqSocket.new
        @socket.connect('tcp://127.0.0.1:5678')
      end

      def send(msg)
        @socket.write(msg)
        @socket.read
      end
      
      def disconnect!
        @socket.close
      end
    end

    class Server
      def initialize
        @socket = BZMQ::RepSocket.new(timeout: 500)
        @socket.bind('tcp://*:5678')
      end
      
      def start
        @running = true
        while @running
          begin
            msg = @socket.read
            @socket.write "Server got: #{msg}"
          rescue BZMQ::SocketError => e
            next if e.error_code == 35 # resource temporarily unavailable (timeout)
            raise e
          end
        end
        @socket.close
       end

      def stop
        @running = false
      end
    end

    client = Client.new
    server = Server.new
    server_thread = Thread.new { server.start }
    puts client.send("Hello server") # prints 'Server got: Hello server'
    client.disconnect!
    server.stop
    server_thread.join
