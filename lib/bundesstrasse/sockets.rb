
module Bundesstrasse
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
