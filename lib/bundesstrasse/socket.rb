module Bundesstrasse
  class Socket
    include Errors

    def initialize(socket, options={})
      @socket = socket
      setup!(options)
    end

    def bind(address)
      @connected = error_check { LibZMQ.zmq_bind(@socket, address) }
    end

    def connect(address)
      @connected = error_check { LibZMQ.zmq_connect(@socket, address) }
    end

    def close!
      !(@connected = !error_check { LibZMQ.zmq_close(@socket) })
    end

    def read(buffer='')
      LibZMQ.zmq_msg do |msg|
        connected_error_check { LibZMQ.zmq_msg_recv(msg, @socket, 0) }
        buffer.replace(LibZMQ.zmq_msg_string(msg))
      end
      buffer
    end

    def write(payload)
      LibZMQ.zmq_msg(payload) do |msg|
        connected_error_check { LibZMQ.zmq_msg_send(msg, @socket, 0) }
      end
    end

    def read_nonblocking(buffer='')
      LibZMQ.zmq_msg do |msg|
        connected_error_check { LibZMQ.zmq_msg_recv(msg, @socket, 1) }
        buffer.replace(LibZMQ.zmq_msg_string(msg))
      end
      buffer
    end

    def write_nonblocking(payload)
      LibZMQ.zmq_msg(payload) do |msg|
        connected_error_check { LibZMQ.zmq_msg_send(msg, @socket, 1) }
      end
    end

    def read_multipart
      messages = []
      LibZMQ.zmq_msg do |msg|
        begin
          connected_error_check { LibZMQ.zmq_msg_recv(msg, @socket, 0) }
          messages << LibZMQ.zmq_msg_string(msg)
        end until LibZMQ.zmq_msg_more(msg).zero?
      end
      messages
    end

    def write_multipart(*parts)
      parts.each_with_index do |part, i|
        send_option = i < parts.size - 1 ? 2 : 0
        LibZMQ.zmq_msg(part) do |msg|
          connected_error_check { LibZMQ.zmq_msg_send(msg, @socket, send_option) }
        end
      end
    end

    def more_parts?
      @rcvmore_option_value ||= FFI::MemoryPointer.new :int
      @rcvmore_option_len ||= FFI::MemoryPointer.new(:size_t).tap { |p| p.write_int(@rcvmore_option_value.size) }
      error_check { LibZMQ.zmq_getsockopt(socket, :rcvmore, @rcvmore_option_value, @rcvmore_option_len) }
      @rcvmore_option_value.read_int > 0
    end

    def type
      @type ||= begin
        type_option_value = FFI::MemoryPointer.new :int
        type_option_len = FFI::MemoryPointer.new(:size_t).tap { |p| p.write_int(type_option_value.size) }
        error_check { LibZMQ.zmq_getsockopt(socket, :type, type_option_value, type_option_len) }
        LibZMQ::SOCKET_TYPES[type_option_value.read_int]
      end
    end

    def pointer
      @socket
    end
    alias_method :socket, :pointer

    def connected?
      @connected
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
      when LibZMQ::NATIVE_ERRORS[:eterm] then close! && TermError.raise_error(e)
      when Errno::EAGAIN::Errno then AgainError.raise_error(e)
      else SocketError.raise_error(e)
      end
    end

    def setup!(options)
      options.each do |option, value|
        error_check { LibZMQ.setsockopt(@socket, option, value) }
      end
    end
  end

  class SubSocket < Socket
    def subscribe(topic)
      setopt(:subscribe, topic)
    end

    def unsubscribe(topic)
      setopt(:unsubscribe, topic)
    end

    private

    def setopt(option, value)
      @option_value ||= FFI::MemoryPointer.new 255
      @option_value.write_string(value)
      error_check { LibZMQ.zmq_setsockopt(socket, option, @option_value, value.bytesize) }
    end
  end

  SocketError = Class.new(ZMQError)
  TermError = Class.new(ZMQError)
  AgainError = Class.new(ZMQError)
end
