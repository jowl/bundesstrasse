
module BZMQ
  class ReqSocket < Socket
    def initialize(options={})
      super(ZMQ::REQ, options)
    end
  end

  class RepSocket < Socket
    def initialize(options={})
      super(ZMQ::REP, options)
    end
  end

  class DealerSocket < Socket
    def initialize(options={})
      super(ZMQ::DEALER, options)
    end
  end

  class RouterSocket < Socket
    def initialize(options={})
      super(ZMQ::ROUTER, options)
    end
  end

  class PushSocket < Socket    
    def initialize(options={})
      super(ZMQ::PUSH, options)
    end
  end

  class PullSocket < Socket
    def initialize(options={})
      super(ZMQ::PULL, options)
    end
  end

  class PubSocket < Socket
    def initialize(options={})
      super(ZMQ::PUB, options)
    end
  end

  class SubSocket < Socket
    def initialize(options={})
      super(ZMQ::SUB, options)
    end
    
    def subscribe(topic)
      error_check { @socket.setsockopt(::ZMQ::SUBSCRIBE, topic) }
    end
    
    def unsubscribe(topic)
      error_check { @socket.setsockopt(::ZMQ::UNSUBSCRIBE, topic) }
    end
  end
end
