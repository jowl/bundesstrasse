module Bundesstrasse
  class QueueDevice < Device
    attr_reader :context
    def initialize(context, frontend, backend)
      device = JZMQ::ZMQQueue.new(context.context, frontend.socket, backend.socket)
      super(device, frontend, backend)
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
    def initialize(context, frontend, backend)
      device = JZMQ::ZMQForwarder.new(context.context, frontend.socket, backend.socket)
      super(device, frontend, backend)
    end

    def self.create(context)
      frontend = context.socket(SubSocket)
      backend = context.socket(PubSocket)
      new(context, frontend, backend)
    end
  end

  class StreamerDevice < Device
    def initialize(context, frontend, backend)
      device = JZMQ::ZMQStreamer.new(context.context, frontend.socket, backend.socket)
      super(device, frontend, backend)
    end

    def self.create(context)
      frontend = context.socket(PullSocket)
      backend = context.socket(PushSocket)
      new(context, frontend, backend)
    end
  end
end
