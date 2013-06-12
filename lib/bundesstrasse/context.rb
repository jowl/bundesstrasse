
module Bundesstrasse
  class Context
    include Errors

    def initialize(zmq_context)
      @zmq_context = zmq_context
    end

    def socket(socket_type, options={})
      raise ContextError, 'Context terminated' if terminated?
      zmq_socket = error_check { LibZMQ.zmq_socket(@zmq_context, socket_type) }
      case socket_type
      when :sub, :xsub, LibZMQ::SOCKET_TYPES[:sub], LibZMQ::SOCKET_TYPES[:xsub]
        SubSocket.new(zmq_socket, options)
      else
        Socket.new(zmq_socket, options)
      end
    rescue ZMQError => e
      ContextError.raise_error(e)
    end

    def terminate!
      LibZMQ.zmq_ctx_destroy(@zmq_context)
      @zmq_context = nil
      true
    end

    def terminated?
      @zmq_context.nil? || @zmq_context.null?
    end

    def self.create(options={})
      zmq_context = LibZMQ.zmq_ctx_new
      options.each do |option, value|
        LibZMQ.zmq_ctx_set(pointer, option, value)
      end
      new(zmq_context)
    end

    private

    def translate_socket_type(type)
      return type unless type.is_a?(Symbol)
      LibZMQ::SOCKET_TYPES[type]
    end

    public

    LibZMQ::SOCKET_TYPES.symbols.each do |type|
      define_method("#{type}_socket") do |options={}|
        socket(type, options)
      end
    end
  end

  ContextError = Class.new(ZMQError)
end
