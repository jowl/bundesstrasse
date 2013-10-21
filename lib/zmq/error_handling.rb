module ZMQ
  ZMQError = Class.new(StandardError)
  InvalidStateError = Class.new(ZMQError)
  IncompatibleProtocolError = Class.new(ZMQError)
  TermError = Class.new(ZMQError)
  NoIOThreadError = Class.new(ZMQError)
  UnknownError = Class.new(ZMQError)

  module ErrorHandling
    private

    def check_rc(&block)
      rc = block.call
      raise last_error if rc < 0
      rc
    end

    def check_res(&block)
      res = block.call
      raise last_error if res.null?
      res
    end

    def last_error
      (NATIVE_ERRORS[errno] || SYSTEM_ERRORS[errno] || UnknownError).new(strerror)
    end

    private
    NATIVE_ERRORS = {
      LibZMQ::NATIVE_ERRORS[:efsm] => InvalidStateError,
      LibZMQ::NATIVE_ERRORS[:enocompatproto] => IncompatibleProtocolError,
      LibZMQ::NATIVE_ERRORS[:eterm] => TermError,
      LibZMQ::NATIVE_ERRORS[:emthread] => NoIOThreadError,
    }
    SYSTEM_ERRORS = Errno.constants.select { |e| e.to_s.start_with?('E') }.map { |e| Errno.const_get(e) }.each_with_object({}) { |e, h| h[e::Errno] = e }

    def errno
      FFI::errno
    end

    def strerror
      LibZMQ.zmq_strerror(errno).read_string
    end
  end
end
