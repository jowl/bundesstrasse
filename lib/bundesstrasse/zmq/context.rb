module Bundesstrasse
  module ZMQ
    class Context
      include ErrorHandling

      attr_reader :pointer

      def initialize
        @pointer = check_res { LibZMQ.zmq_ctx_new }
      end

      def set(option_name, option_value)
        check_rc { LibZMQ.zmq_ctx_set(@pointer, option_name, option_value) }
      end

      def get(option_name)
        check_rc { LibZMQ.zmq_ctx_get(@pointer, option_name) }
      end

      def destroy
        check_rc { LibZMQ.zmq_ctx_destroy(@pointer) }
      end

      def socket(type)
        Socket.new(check_res { LibZMQ.zmq_socket(@pointer, type) })
      end
    end
  end
end
