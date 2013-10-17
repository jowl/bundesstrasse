module Bundesstrasse
  class Socket

    DEFAULT_OPTIONS = { linger: 0 }

    def initialize(socket, options={})
      @zmq_socket = socket
      DEFAULT_OPTIONS.merge(options).each do |option_name, option_value|
        @zmq_socket.setsockopt(option_name, option_value)
      end
    end

    def connect(endpoint)
      @zmq_socket.connect(endpoint)
    end

    def bind(endpoint)
      @zmq_socket.bind(endpoint)
    end

    def pointer
      @zmq_socket.pointer
    end

    def type
      @type ||= ZMQ::LibZMQ::SOCKET_TYPES[@zmq_socket.getsockopt(:type)]
    end

    def readable?
      (events & ZMQ::LibZMQ::EVENT_FLAGS[:pollin]) > 0
    end

    def writable?
      (events & ZMQ::LibZMQ::EVENT_FLAGS[:pollout]) > 0
    end

    def recv(option=0)
      ZMQ::Message.open do |msg|
        msg.recv(@zmq_socket, option)
        msg.data
      end
    end

    def recv_multipart(option=0)
      ZMQ::Message.open do |msg|
        parts = []
        begin
          msg.recv(@zmq_socket, option)
          parts << msg.data
        end until !msg.more
        parts
      end
    end

    def send(*parts)
      options = [:sndmore]
      options << parts.pop if parts.last == :dontwait
      last = parts.size - 1
      parts.each_with_index do |part, index|
        options.delete(:sndmore) if index == last
        @zmq_socket.send(part, *options)
      end
    end

    def more?
      @zmq_socket.getsockopt(:rcvmore)
    end

    def disconnect(endpoint)
      @zmq_socket.disconnect(endpoint)
    end

    def unbind(endpoint)
      @zmq_socket.unbind(endpoint)
    end

    def close
      @zmq_socket.close
    rescue Errno::ENOTSOCK
    end

    def closed?
      @zmq_socket.pointer.nil?
    end

    private

    def events
      @zmq_socket.getsockopt(:events)
    end
  end

  class SubSocket < Socket
    def subscribe(topic)
      @zmq_socket.setsockopt(:subscribe, topic)
    end

    def unsubscribe(topic)
      @zmq_socket.setsockopt(:unsubscribe, topic)
    end
  end

  class XSubSocket < Socket
    def subscribe(topic)
      @zmq_socket.send("\1#{topic}")
    end

    def unsubscribe(topic)
      @zmq_socket.send("\0#{topic}")
    end
  end
end
