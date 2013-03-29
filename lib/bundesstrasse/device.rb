
module Bundesstrasse
  class Device
    include Errors

    attr_reader :frontend, :backend
    def initialize(device, frontend, backend)
      @device = device
      @frontend = frontend
      @backend = backend
    end

    def start
      error_check do
        @device.run
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
      when JZMQ::ZMQ.ETERM then close!
      else DeviceError.raise_error(e)
      end
    end
  end

  DeviceError = Class.new(ZMQError)
end
