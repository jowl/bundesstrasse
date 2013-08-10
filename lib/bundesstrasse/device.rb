
module Bundesstrasse
  class Device
    include Errors

    attr_reader :frontend, :backend
    def initialize(frontend, backend)
      @frontend = frontend
      @backend = backend
    end

    def start
      error_check do
        LibZMQ.zmq_proxy(@frontend.pointer, @backend.pointer, nil)
      end
    end

    private

    def close!
      @frontend.close!
      @backend.close!
    end

    def error_check(&block)
      super
    rescue ZMQError => e
      case e.error_code
      when LibZMQ::NATIVE_ERRORS[:eterm] then close!
      else DeviceError.raise_error(e)
      end
    end
  end

  DeviceError = Class.new(ZMQError)
end
