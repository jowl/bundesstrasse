module ZMQ
  class Message
    include ErrorHandling
    include Helpers

    attr_reader :pointer
    def initialize(data=nil)
      @pointer = FFI::MemoryPointer.new LibZMQ::ZMQ_MSG_T, 1, false
      if data
        check_rc { LibZMQ.zmq_msg_init_size(@pointer, data.bytesize) }
        data_pointer.write_bytes(data)
      else
        LibZMQ.zmq_msg_init(@pointer)
      end
    end

    def close
      return unless @pointer
      check_rc { LibZMQ.zmq_msg_close(@pointer) }
      @pointer = nil
    end

    def closed?
      @pointer.nil?
    end

    def data
      data_pointer.read_bytes(size)
    end

    def recv(socket, *flags)
      check_rc { LibZMQ.zmq_msg_recv(@pointer, socket.pointer, send_recv_opts(flags)) }
      nil
    rescue TermError
      close
      socket.close
      raise
    end

    def send(socket, *flags)
      check_rc { LibZMQ.zmq_msg_send(@pointer, socket.pointer, send_recv_opts(flags)) }
      nil
    rescue TermError
      close
      socket.close
      raise
    end

    def size
      LibZMQ.zmq_msg_size(@pointer)
    end

    def more
      LibZMQ.zmq_msg_more(@pointer) == 1
    end

    def self.open(data=nil)
      msg = new(data)
      begin
        yield msg
      ensure
        begin
          msg.close
        rescue Errno::EFAULT
        end
      end
    end

    private

    def data_pointer
      check_res { LibZMQ.zmq_msg_data(@pointer) }
    end
  end
end

