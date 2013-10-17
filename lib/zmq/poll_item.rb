module ZMQ
  class PollItem < FFI::Struct
    layout :socket,  :pointer,
           :fd,      :int,
           :events,  :short,
           :revents, :short

    def socket
      self[:socket]
    end

    def socket=(socket)
      self[:socket] = socket
    end

    def fd
      self[:fd]
    end

    def fd=(fd)
      self[:fd] = fd
    end

    def events
      self[:events]
    end

    def events=(events)
      self[:events] = events
    end

    def readable?
      (self[:revents] & LibZMQ::EVENT_FLAGS[:pollin]) > 0
    end

    def writable?
      (self[:revents] & LibZMQ::EVENT_FLAGS[:pollout]) > 0
    end

    def self.create_array(poll_items)
      pointer = FFI::MemoryPointer.new(size, poll_items.size, true)
      poll_items.each_with_index do |poll_item, i|
        pointer.put_bytes(i*poll_item.size, poll_item.pointer.read_bytes(poll_item.size), 0, poll_item.size)
      end
      pointer
    end
  end
end
