
module Bundesstrasse
  class Context
    include Errors

    def initialize(zmq_context)
      @zmq_context = zmq_context
    end

    def socket(socket_type, options={})
      raise ContextError, 'Context terminated' if terminated?
      socket_type = translate_socket_type(socket_type)
      zmq_socket = error_check { @zmq_context.socket(socket_type) }
      case socket_type
      when ZMQ::SUB, ZMQ::XSUB
        SubSocket.new(zmq_socket, options)
      else
        Socket.new(zmq_socket, options)
      end
    rescue ZMQError => e
      ContextError.raise_error(e)
    end

    def terminate!
      @zmq_context.terminate
      true
    end

    def terminated?
      @zmq_context.context.nil?
    end

    def self.create(options={})
      new ZMQ::Context.create(options[:io_threads] || 1)
    end

    private

    SYMBOLIC_TYPES_LOW  = [:pair, :pub, :sub, :req, :rep, :dealer, :router, :pull, :push, :xpub, :xsub].freeze
    SYMBOLIC_TYPES_HIGH = SYMBOLIC_TYPES_LOW.map { |s| s.upcase }.freeze

    def translate_socket_type(type)
      return type unless type.is_a?(Symbol)
      SYMBOLIC_TYPES_LOW.index(type) || SYMBOLIC_TYPES_HIGH.index(type)
    end
  end

  ContextError = Class.new(ZMQError)
end
