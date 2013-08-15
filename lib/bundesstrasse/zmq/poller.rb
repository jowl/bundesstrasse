require 'bundesstrasse/zmq/poll_item'

module Bundesstrasse
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
          rc = check_rc { LibZMQ.zmq_poll(items, @pollables.size, timeout) }
          if rc > 0
            @pollables.each_with_index do |(pollable, _), i|
              poll_item = PollItem.new(items + i * PollItem.size)
              readables << pollable if poll_item.readable?
              writables << pollable if poll_item.writable?
            end
          end
        end
        Accessibles.new(readables, writables)
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

      class Accessibles < Struct.new(:readables, :writables)
        def any?
          !readables.empty? || !writables.empty?
        end

        def none?
          !any?
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
            if pollable.is_a? Socket
              poll_item.socket = pollable.pointer
            else
              poll_item.fd = pollable.fileno
            end
            poll_item.events = events
          end
        end
        @dirty = false
        @items = PollItem.create_array(poll_items)
      end
    end
  end
end
