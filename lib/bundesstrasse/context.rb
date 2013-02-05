
module Bundesstrasse
  ContextError = Class.new(StandardError)

  class Context
    def self.context(io_threads=1)
      @io_threads = io_threads unless @context
      raise ContextError unless @io_threads == io_threads
      @context ||= ZMQ::Context.create io_threads
    end
  end
end
