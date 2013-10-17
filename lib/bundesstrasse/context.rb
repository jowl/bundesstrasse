module Bundesstrasse
  class Context
    def initialize(options={})
      @zmq_context = ZMQ::Context.new
      options.each do |option_name, option_value|
        @zmq_context.set(option_name, option_value)
      end
    end

    def destroy
      @zmq_context.destroy
    rescue Errno::EFAULT
    end

    def destroyed?
      @zmq_context.pointer.nil?
    end

    ZMQ::LibZMQ::SOCKET_TYPES.symbols.each do |type|
      define_method("#{type}_socket") do |options={}|
        socket(type, options)
      end
    end

    private

    def socket(type, options)
      Socket.new(@zmq_context.socket(type), options)
    end
  end
end
