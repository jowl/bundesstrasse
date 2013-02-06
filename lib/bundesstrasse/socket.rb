
module Bundesstrasse
  class Socket
    def initialize(type, options={})
      options = options.dup
      context = Context.context(options.delete(:io_threads) || 1)
      @socket = context.socket(type)
      raise SocketError unless @socket
      DEFAULT_OPTIONS.merge(options).each do |option, value|
        begin
          error_check { @socket.setsockopt ZMQ.const_get(option.upcase), value }
        rescue NameError => e
          raise ArgumentError, "Unknown socket option '#{option}'", e.backtrace
        end
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
      unless ZMQ::Util.resultcode_ok? block.call
        error_class = case errno
                      when ZMQ::ETERM  then TermError
                      when ZMQ::EAGAIN then AgainError
                      else SocketError
                      end
        raise error_class.new(error_string, errno)
      end
      true
    end

    def errno
      ZMQ::Util.errno
    end

    def error_string
      ZMQ::Util.error_string
    end

    DEFAULT_OPTIONS = {
      linger: 0,
      rcvtimeo: -1,
      sndtimeo: -1,
    }
  end

  class SocketError < StandardError
    attr_reader :error_code
    def initialize(message, error_code=-1)
      @error_code = error_code
      super(message)
    end
  end

  TermError = Class.new(SocketError)
  AgainError = Class.new(SocketError)
end
