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
    def errno
      LibZMQ.errno
    end

    def error_string
      LibZMQ.strerror
    end

    def error_check(&block)
      if (res = block.call).is_a? Fixnum
        res = res >= 0
      end
      raise ZMQError.new(error_string, errno) unless res
      res
    end
  end
end
