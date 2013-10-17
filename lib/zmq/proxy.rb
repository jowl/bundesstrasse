module ZMQ
  class Proxy
    include ErrorHandling

    attr_reader :frontend, :backend, :capture
    def initialize(frontend, backend, capture=nil)
      @frontend = frontend
      @backend = backend
      @capture = capture
    end

    def start
      check_rc do
        LibZMQ.zmq_proxy(@frontend.pointer, @backend.pointer, @capture && @capture.pointer)
      end
    rescue TermError
      close
    end

    private

    def close
      @frontend.close
      @backend.close
      @capture.close if @capture
    end
  end
end

