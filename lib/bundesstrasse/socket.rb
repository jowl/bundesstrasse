module Bundesstrasse
  class Socket
    include Errors

    def initialize(socket, options={})
      @socket = socket
    end

    def bind(address)
      error_check { @socket.bind(address) }
      @connected = true
    end

    def connect(address)
      error_check { @socket.connect(address) }
      @connected = true
    end

    def close!
      error_check { @socket.close }
      @connected = false
      true
    end

    def read(buffer='')
      connected_error_check { buffer.replace(@socket.recv_str) }
    end

    def write(message)
      connected_error_check { @socket.send(message) }
    end

    def read_nonblocking(buffer='')
      connected_error_check do
        data = @socket.recv_str(JZMQ::ZMQ::NOBLOCK)
        data && buffer.replace(data)
      end
    end

    def write_nonblocking(message)
      connected_error_check { @socket.send(message, JZMQ::ZMQ::NOBLOCK) }
    end

    def read_multipart
      messages = [read]
      messages << read while error_check { @socket.has_receive_more }
      messages
    end

    def write_multipart(*parts)
      last = parts.pop
      parts.each do |part|
        connected_error_check { @socket.send_more(part) }
      end
      connected_error_check { @socket.send(last) }
    end

    def more_parts?
      error_check { @socket.has_receive_more }
    end

    def pointer
      @socket
    end
    alias_method :socket, :pointer

    def connected?
      @connected
    end

    def self.type
      raise NotImplementedError, 'Subclasses must override Socket::type'
    end

    private

    def connected_error_check(&block)
      raise SocketError, 'Not connected' unless connected?
      error_check(&block)
    end

    def error_check(&block)
      super
    rescue ZMQError => e
      case e.error_code
      when JZMQ::ZMQ.ETERM then close! && TermError.raise_error(e)
#      when JZMQ::ZMQ::EAGAIN then AgainError.raise_error(e)
      else SocketError.raise_error(e)
      end
    end
  end

  SocketError = Class.new(ZMQError)
  TermError = Class.new(ZMQError)
  AgainError = Class.new(ZMQError)
end
