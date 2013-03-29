module Bundesstrasse
  class ZMQError < StandardError
    attr_reader :error_code
    def initialize(message, error_code=-1)
      @error_code = error_code
      super(message)
    end

    def self.raise_error(e)
      raise new(e.message, e.error_code)
    end
  end

  module Errors
    def error_check(&block)
      block.call
    rescue JZMQ::ZMQException => e
      raise ZMQError.new(e.message, e.error_code)
    end
  end
end
