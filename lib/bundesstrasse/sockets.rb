
module Bundesstrasse
  class ReqSocket < Socket
    def self.type
      JZMQ::ZMQ::REQ
    end
  end

  class RepSocket < Socket
    def self.type
      JZMQ::ZMQ::REP
    end
  end

  class DealerSocket < Socket
    def self.type
      JZMQ::ZMQ::DEALER
    end
  end

  class RouterSocket < Socket
    def self.type
      JZMQ::ZMQ::ROUTER
    end
  end

  class PushSocket < Socket
    def self.type
      JZMQ::ZMQ::PUSH
    end
  end

  class PullSocket < Socket
    def self.type
      JZMQ::ZMQ::PULL
    end
  end

  class PubSocket < Socket
    def self.type
      JZMQ::ZMQ::PUB
    end
  end

  class SubSocket < Socket
    def self.type
      JZMQ::ZMQ::SUB
    end

    def subscribe(topic)
      error_check { @socket.subscribe(topic.to_java_bytes) }
    end

    def unsubscribe(topic)
      error_check { @socket.subscribe(topic.to_java_bytes) }
    end
  end

  class XPubSocket < Socket
    def self.type
      JZMQ::ZMQ::XPUB
    end
  end

  class XSubSocket < SubSocket
    def self.type
      JZMQ::ZMQ::XSUB
    end
  end
end
