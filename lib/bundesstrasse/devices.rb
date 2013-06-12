module Bundesstrasse
  class QueueDevice < Device
    attr_reader :context
    def initialize(context, frontend, backend)
      super(frontend, backend)
      @context = context
    end

    def create_endpoint!(options={})
      @context.rep_socket(options)
    end

    def self.create(context)
      frontend = context.router_socket
      backend = context.router_socket
      new(context, frontend, backend)
    end
  end

  class ForwarderDevice < Device
    def initialize(frontend, backend)
      super(frontend, backend)
    end

    def self.create(context)
      frontend = context.sub_socket
      backend = context.pub_socket
      new(frontend, backend)
    end
  end

  class StreamerDevice < Device
    def initialize(frontend, backend)
      super(frontend, backend)
    end

    def self.create(context)
      frontend = context.pull_socket
      backend = context.push_socket
      new(frontend, backend)
    end
  end
end
