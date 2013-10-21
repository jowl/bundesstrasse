require 'zmq/pointers'

module ZMQ
  class Socket
    include ErrorHandling
    include Helpers

    attr_reader :pointer
    def initialize(pointer)
      @pointer = pointer
      @option_pointers = {}
      @option_len = FFI::MemoryPointer.new(:size_t)
    end

    def bind(endpoint)
      check_rc { LibZMQ.zmq_bind(@pointer, endpoint) }
      nil
    end

    def connect(endpoint)
      check_rc { LibZMQ.zmq_connect(@pointer, endpoint) }
      nil
    end

    def getsockopt(option_name)
      option_value_pointer = (@option_pointers[option_name] ||= create_pointer(LibZMQ.sockopts[option_name].type))
      @option_len.write_int(option_value_pointer.size)
      check_rc { LibZMQ.zmq_getsockopt(@pointer, option_name, option_value_pointer.address, @option_len) }
      option_value_pointer.size = @option_len.read_int
      option_value_pointer.value
    end

    def setsockopt(option_name, option_value)
      option_value_pointer = create_pointer(LibZMQ.sockopts[option_name].type, option_value)
      check_rc { LibZMQ.zmq_setsockopt(@pointer, option_name, option_value_pointer.address, option_value_pointer.size) }
      nil
    end

    def send(data, *flags)
      buffer = create_pointer(:bytes, data)
      check_rc { LibZMQ.zmq_send(@pointer, buffer.address, buffer.size, send_recv_opts(flags)) }
      nil
    end

    def recv(len, *flags)
      buffer = FFI::MemoryPointer.new(len, 1, true)
      check_rc { LibZMQ.zmq_recv(@pointer, buffer, len, send_recv_opts(flags)) }
      buffer.read_bytes(len)
    end

    def close
      check_rc { LibZMQ.zmq_close(@pointer) }
      @pointer = nil
    end

    def closed?
      @pointer.nil?
    end

    def disconnect(endpoint)
      check_rc { LibZMQ.zmq_disconnect(@pointer, endpoint) }
      nil
    end

    def unbind(endpoint)
      check_rc { LibZMQ.zmq_unbind(@pointer, endpoint) }
      nil
    end

    private

    def check_rc(&block)
      super
    rescue TermError
      close
      raise
    end

    def create_pointer(type, val=nil)
      case type
      when :string, :bytes then BytesPointer.new(val)
      when :boolean then BooleanPointer.new(val)
      when :time_period then TimePointer.new(val)
      else ValuePointer.new(type, val)
      end
    end
  end
end

