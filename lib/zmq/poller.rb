require 'zmq/poll_item'

module ZMQ
  class Poller
    include ErrorHandling

    def initialize
      @pollables = Hash.new(0)
    end

    def poll(timeout=-1)
      readables = []
      writables = []
      unless @pollables.empty?
        if check_rc { LibZMQ.zmq_poll(items, @pollables.size, (timeout >= 0 ? (timeout * 1000).round : -1)) } > 0
          @pollables.each_with_index do |(pollable, _), i|
            poll_item = PollItem.new(items + i * PollItem.size)
            readables << pollable if poll_item.readable?
            writables << pollable if poll_item.writable?
          end
        end
      end
      PollResult.new(readables, writables)
    end

    def register(pollable, *events)
      @dirty = true
      events = events.reduce(0) { |events, event| events | translate_event(event) }
      @pollables[pollable] = events > 0 ? events : IN_OUT
    end

    def unregister(pollable)
      @dirty = true
      @pollables.delete(pollable)
    end

    class PollResult
      attr_reader :readables, :writables

      def initialize(readables, writables)
        @ary = (@readables, @writables = readables, writables)
      end

      def any?
        @readables.any? || @writables.any?
      end

      def to_ary
        @ary
      end
    end

    private

    IN_OUT = LibZMQ::EVENT_FLAGS[:pollin] | LibZMQ::EVENT_FLAGS[:pollout]

    def translate_event(event)
      event.is_a?(Symbol) ? LibZMQ::EVENT_FLAGS[event] : event
    end

    def items
      return @items unless @dirty
      poll_items = @pollables.map do |pollable, events|
        PollItem.new.tap do |poll_item|
          if pollable.is_a? IO
            poll_item.fd = fileno(pollable)
          else
            poll_item.socket = pollable.pointer
          end
          poll_item.events = events
        end
      end
      @dirty = false
      @items = PollItem.create_array(poll_items)
    end

    if defined?(JRuby)
      def fileno(io)
        # The JVM has internal file descriptors, this is to get the real OS file descriptor
        JRuby.reference(io).open_file.main_stream.descriptor.channel.fd_val
      end
    else
      def fileno(io)
        io.fileno
      end
    end
  end
end
