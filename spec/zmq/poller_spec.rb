require 'spec_helper'
require 'tempfile'

module ZMQ
  describe Poller do
    let :poller do
      described_class.new
    end

    let :context do
      Context.new
    end

    let :io_pipe do
      require 'socket'
      IO.pipe.last
    end

    let! :rep_socket do
      context.socket(:rep).tap do |s|
        s.bind('inproc://poller_spec')
      end
    end

    let! :req_socket do
      context.socket(:req).tap do |s|
        s.connect('inproc://poller_spec')
      end
    end

    let :message do
      Message.new
    end

    after do
      io_pipe.close
      message.close unless message.closed?
      req_socket.close unless req_socket.closed?
      rep_socket.close unless rep_socket.closed?
      context.destroy unless context.destroyed?
    end

    describe '#register' do
      it 'registers for both pollin and pollout unless otherwise specified' do
        poller.register(rep_socket)
        message.send(req_socket) # make rep readable
        res = poller.poll(0)
        res.readables.should include(rep_socket)
        message.recv(rep_socket)
        res = poller.poll(0)
        res.writables.should include(rep_socket)
      end

      it 'is possible to re-register for other event' do
        message.send(req_socket)
        poller.register(rep_socket, :pollin)
        res = poller.poll(0)
        res.readables.should include(rep_socket)
        poller.register(rep_socket, :pollout)
        poller.poll(0).should_not be_any
        message.recv(rep_socket)
        res = poller.poll(0)
        res.writables.should include(rep_socket)
      end

      it 'is possible to register file handles' do
        poller.register(io_pipe)
        res = poller.poll(0)
        res.writables.should include(io_pipe)
      end
    end

    describe '#unregister' do
      it 'no longer considers pollable' do
        poller.register(req_socket)
        res = poller.poll(0)
        res.writables.should include(req_socket)
        poller.unregister(req_socket)
        poller.poll(0).should_not be_any
      end
    end

    describe '#poll' do
      it "returns a #{described_class::PollResult}" do
        poller.poll(0).should be_a(described_class::PollResult)
      end

      it 'waits for timeout seconds' do
        timeout = 0.1
        poller.register(rep_socket)
        t0 = Time.now
        poller.poll(timeout)
        (Time.now - t0).should >= timeout
      end
    end

    describe described_class::PollResult do
      before do
        poller.register(rep_socket)
        poller.register(req_socket)
      end

      describe '#any?' do
        it 'returns true if there are any accessible items' do
          poller.poll(0).any?.should be_true
        end

        it "returns false if there aren't any accessible items" do
          poller.unregister(req_socket)
          poller.poll(0).any?.should be_false
        end
      end

      describe '#writables' do
        it 'returns writable items' do
          res = poller.poll(0)
          res.writables.should include(req_socket)
        end

        it 'returns empty array if none are writable' do
          message.send(req_socket)
          res = poller.poll(0)
          res.writables.should be_empty
        end
      end

      describe '#readables' do
        it 'returns empty array if none are readable' do
          res = poller.poll(0)
          res.readables.should be_empty
        end

        it 'returns readable items' do
          message.send(req_socket)
          res = poller.poll(0)
          res.readables.should include(rep_socket)
        end
      end

      describe '#to_ary' do
        it 'returns readable and writable objects' do
          readables, writables = poller.poll(0)
          readables.should be_empty
          writables.should include(req_socket)
        end
      end
    end
  end
end
