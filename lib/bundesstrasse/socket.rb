module Bundesstrasse
  class Socket
    include Errors

    def initialize(socket, options={})
      @socket = socket
      setup!(options)
    end

    def bind(address)
      @connected = error_check { @socket.bind(address) }
    end

    def connect(address)
      @connected = error_check { @socket.connect(address) }
    end

    def close!
      !(@connected = !error_check { @socket.close })
    end

    def read(buffer='')
      connected_error_check { @socket.recv_string buffer }
      buffer
    end

    def write(message)
      connected_error_check { @socket.send_string(message) }
    end

    def read_nonblocking(buffer='')
      connected_error_check { @socket.recv_string(buffer, ZMQ::NonBlocking) }
      buffer
    end

    def write_nonblocking(message)
      connected_error_check { @socket.send_string(message, ZMQ::NonBlocking) }
    end

    def read_multipart
      messages = []
      connected_error_check { @socket.recv_strings(messages) }
      messages
    end

    def write_multipart(*parts)
      connected_error_check { @socket.send_strings(parts) }
    end

    def more_parts?
      @socket.more_parts?
    end

    def pointer
      @socket.socket
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
      when ZMQ::ETERM then close! && TermError.raise_error(e)
      when ZMQ::EAGAIN then AgainError.raise_error(e)
      else SocketError.raise_error(e)
      end
    end

    def setup!(options)
      options.each do |option, value|
        begin
          error_check { @socket.setsockopt ZMQ.const_get(option.upcase), value }
        rescue NameError => e
          raise ArgumentError, "Unknown socket option '#{option}'", e.backtrace
        end
      end
    end
  end

  class SubSocket < Socket
    def subscribe(topic)
      error_check { @socket.setsockopt(ZMQ::SUBSCRIBE, topic) }
    end

    def unsubscribe(topic)
      error_check { @socket.setsockopt(ZMQ::UNSUBSCRIBE, topic) }
    end
  end

  SocketError = Class.new(ZMQError)
  TermError = Class.new(ZMQError)
  AgainError = Class.new(ZMQError)
end
