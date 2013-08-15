require 'bundesstrasse/zmq/pointers'

module Bundesstrasse
  module ZMQ
    class Socket
      include ErrorHandling

      attr_reader :pointer
      def initialize(pointer)
        @pointer = pointer
        @option_pointers = {}
        @option_len = FFI::MemoryPointer.new(:size_t)
      end

      def bind(endpoint)
        check_rc { LibZMQ.zmq_bind(@pointer, endpoint) }
      end

      def connect(endpoint)
        check_rc { LibZMQ.zmq_connect(@pointer, endpoint) }
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
      end

      def close
        check_rc { LibZMQ.zmq_close(@pointer) }
      end

      def disconnect(endpoint)
        check_rc { LibZMQ.zmq_disconnect(@pointer, endpoint) }
      end

      def unbind(endpoint)
        check_rc { LibZMQ.zmq_unbind(@pointer, endpoint) }
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
        else ValuePointer.new(type, val)
        end
      end
    end
  end
end
