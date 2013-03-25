module Bundesstrasse
  class QueueDevice < Device
    attr_reader :context
    def initialize(context, frontend, backend)
      super(ZMQ::QUEUE, frontend, backend)
      @context = context
    end
    
    def create_endpoint!(options={})
      @context.socket(RepSocket, options)
    end

    def self.create(context)
      frontend = context.socket(RouterSocket)
      backend = context.socket(DealerSocket)
      new(context, frontend, backend)
    end
  end

  class ForwarderDevice < Device
    def initialize(frontend, backend)
      super(ZMQ::FORWARDER, frontend, backend)
    end
    
    def self.create(context)
      frontend = context.socket(SubSocket)
      backend = context.socket(PubSocket)
      new(frontend, backend)
    end
  end

  class StreamerDevice < Device
    def initialize(frontend, backend)
      super(ZMQ::STREAMER, frontend, backend)
    end
    
    def self.create(context)
      frontend = context.socket(PullSocket)
      backend = context.socket(PushSocket)
      new(frontend, backend)
    end
  end
end
