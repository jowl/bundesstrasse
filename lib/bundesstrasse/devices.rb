module Bundesstrasse
  class QueueDevice < Device
    attr_reader :context
    def initialize(context, frontend, backend)
      super(ZMQ::QUEUE, frontend, backend)
      @context = context
    end
    
    def create_endpoint!(options={})
      @context.socket(ZMQ::REP, options)
    end

    def self.create(context)
      frontend = context.socket(ZMQ::ROUTER)
      backend = context.socket(ZMQ::DEALER)
      new(context, frontend, backend)
    end
  end

  class ForwarderDevice < Device
    def initialize(frontend, backend)
      super(ZMQ::FORWARDER, frontend, backend)
    end
    
    def self.create(context)
      frontend = context.socket(ZMQ::SUB)
      backend = context.socket(ZMQ::PUB)
      new(frontend, backend)
    end
  end

  class StreamerDevice < Device
    def initialize(frontend, backend)
      super(ZMQ::STREAMER, frontend, backend)
    end
    
    def self.create(context)
      frontend = context.socket(ZMQ::PULL)
      backend = context.socket(ZMQ::PUSH)
      new(frontend, backend)
    end
  end
end
