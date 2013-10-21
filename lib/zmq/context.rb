module ZMQ
  class Context
    include ErrorHandling

    attr_reader :pointer

    def initialize
      @pointer = check_res { LibZMQ.zmq_ctx_new }
    end

    def set(option_name, option_value)
      check_rc { LibZMQ.zmq_ctx_set(@pointer, option_name, option_value) }
      nil
    end

    def get(option_name)
      check_rc { LibZMQ.zmq_ctx_get(@pointer, option_name) }
    end

    def destroy
      check_rc { LibZMQ.zmq_ctx_destroy(@pointer) }
      @pointer = nil
    end

    def destroyed?
      @pointer.nil?
    end

    def socket(type)
      Socket.new(zmq_socket(type))
    end

    private

    def zmq_socket(type)
      check_res { LibZMQ.zmq_socket(@pointer, type) }
    end
  end
end

