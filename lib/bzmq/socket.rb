
module BZMQ
  class Socket
    SocketError = Class.new(StandardError)

    def initialize(type, options={})
      @context = Context.context(options[:io_threads] || 1)
      @socket = @context.socket(type)
      raise SocketError unless @socket
      error_check do
        @socket.setsockopt ZMQ::LINGER, options[:linger] || -1
        @socket.setsockopt ZMQ::RCVTIMEO, options[:timeout] || -1
        @socket.setsockopt ZMQ::SNDTIMEO, options[:timeout] || -1
      end
    end

    def bind(address)
      @connected = error_check { @socket.bind(address) }
    end

    def connect(address)
      @connected = error_check { @socket.connect(address) }
    end

    def close
      !(@connected = !error_check { @socket.close })
    end

    def read(buffer='')
      connected_error_check { @socket.recv_string buffer }
      buffer
    end

    def write(message)
      connected_error_check { @socket.send_string message }
    end

    private

    def connected_error_check(&block)
      raise SocketError, 'Not connected' unless @connected
      error_check(&block)
    end

    def error_check(&block)
      raise SocketError, ZMQ::Util.error_string unless ZMQ::Util.resultcode_ok? block.call
      true
    end
  end
end
