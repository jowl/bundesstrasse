
module Bundesstrasse
  class ReqSocket < Socket
    def self.type
      ZMQ::REQ
    end
  end

  class RepSocket < Socket
    def self.type
      ZMQ::REP
    end
  end

  class DealerSocket < Socket
    def self.type
      ZMQ::DEALER
    end
  end

  class RouterSocket < Socket
    def self.type
      ZMQ::ROUTER
    end
  end

  class PushSocket < Socket    
    def self.type
      ZMQ::PUSH
    end
  end

  class PullSocket < Socket
    def self.type
      ZMQ::PULL
    end
  end

  class PubSocket < Socket
    def self.type
      ZMQ::PUB
    end
  end

  class SubSocket < Socket
    def self.type
      ZMQ::SUB
    end
    
    def subscribe(topic)
      error_check { @socket.setsockopt(ZMQ::SUBSCRIBE, topic) }
    end
    
    def unsubscribe(topic)
      error_check { @socket.setsockopt(ZMQ::UNSUBSCRIBE, topic) }
    end
  end
end
