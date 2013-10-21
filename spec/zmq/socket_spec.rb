require 'spec_helper'

module ZMQ
  describe Socket do
    let :context do
      Context.new
    end

    let :socket do
      context.socket(:req).tap { |s| s.setsockopt(:linger, 0) }
    end

    after do
      unless context.destroyed?
        socket.close unless socket.closed?
        context.destroy
      end
    end

    def self.term_error(&block)
      it "raises TermError and closes socket if context has been destroyed" do
        socket
        t = Thread.new { context.destroy }
        sleep 0.1 # there's no way of nowing when the context destruction has begun
        expect { instance_exec(&block) }.to raise_error(TermError)
        t.join
        expect { socket.close }.to raise_error(Errno::ENOTSOCK)
      end
    end

    describe '#bind' do
      it 'binds to the specified endpoint' do
        socket.bind('tcp://0.0.0.0:7788')
        socket.getsockopt(:last_endpoint).should == 'tcp://0.0.0.0:7788'
      end

      it 'raises EPROTONOSUPPORT for unsupported protocols' do
        expect { socket.bind('smtp://0.0.0.0:7788') }.to raise_error(Errno::EPROTONOSUPPORT)
      end

      it 'raises EINVAL for invalid address' do
        expect { socket.bind('this-is-not-a-valid-endpoint') }.to raise_error(Errno::EINVAL)
      end

      it 'raises EADDRINUSE when binding to same address more than once' do
        socket.bind('tcp://0.0.0.0:7788')
        expect { socket.bind('tcp://0.0.0.0:7788') }.to raise_error(Errno::EADDRINUSE)
      end

      it 'raises ENODEV for non-existent interfaces' do
        expect { socket.bind('tcp://this-endpoint-does-not-exist:7788') }.to raise_error(Errno::ENODEV)
      end

      term_error { socket.bind('tcp://0.0.0.0:7788') }
    end

    describe '#connect' do
      it 'connects to the specified endpoint' do
        socket.connect('tcp://127.0.0.1:7788')
        socket.getsockopt(:last_endpoint).should == 'tcp://127.0.0.1:7788'
      end

      it 'raises EPROTONOSUPPORT for unsupported protocols' do
        expect { socket.connect('smtp://127.0.0.1:7788') }.to raise_error(Errno::EPROTONOSUPPORT)
      end

      it 'raises EINVAL for invalid address' do
        expect { socket.connect('this-is-not-a-valid-endpoint') }.to raise_error(Errno::EINVAL)
      end

      term_error { socket.connect('tcp://127.0.0.1:7788') }
    end

    describe '#setsockopt/#getsockopt' do
      context 'with boolean options' do
        [:ipv4only, :delay_attach_on_connect].each do |option_name|
          it "sets and gets #{option_name}" do
            socket.setsockopt(option_name, true)
            socket.getsockopt(option_name).should be_true
            socket.setsockopt(option_name, false)
            socket.getsockopt(option_name).should be_false
          end
        end
      end

      context 'with numerical options' do
        [:affinity, :rate, :sndbuf, :rcvbuf, :backlog, :maxmsgsize, :sndhwm, :rcvhwm, :multicast_hops].each do |option_name|
          it "sets and gets #{option_name}" do
            socket.setsockopt(option_name, 101)
            socket.getsockopt(option_name).should == 101
          end
        end
      end

      context 'with time period options' do
        [:recovery_ivl, :reconnect_ivl_max].each do |option_name|
          it "sets and gets #{option_name}" do
            socket.setsockopt(option_name, 10.1)
            socket.getsockopt(option_name).should == 10.1
          end
        end

        context 'that can be negative (indefinite)' do
          [:linger, :reconnect_ivl, :rcvtimeo, :sndtimeo].each do |option_name|
            it "sets and gets #{option_name}" do
              socket.setsockopt(option_name, -10.1)
              socket.getsockopt(option_name).should == -1
              socket.setsockopt(option_name, 10.1)
              socket.getsockopt(option_name).should == 10.1
            end
          end
        end
      end

      context 'with string options' do
        it 'sets and gets identity' do
          socket.setsockopt(:identity, 'spec id')
          socket.getsockopt(:identity).should == 'spec id'
        end
      end

      it 'raises ArgumentError for unknown options' do
        expect { socket.setsockopt(:unknown, '') }.to raise_error(ArgumentError)
        expect { socket.getsockopt(:unknown) }.to raise_error(ArgumentError)
      end

      it 'raises EINVAL when setting invalid propery values' do
        expect { socket.setsockopt(:identity, '') }.to raise_error(Errno::EINVAL)
      end

      it 'raises ENOTSOCK when socket has been closed' do
        socket.close
        expect { socket.setsockopt(:ipv4only, 1) }.to raise_error(Errno::ENOTSOCK)
        expect { socket.getsockopt(:ipv4only) }.to raise_error(Errno::ENOTSOCK)
      end
    end

    context 'send and receive' do
      let :sender do
        socket
      end

      let :receiver do
        receiver = context.socket(:rep).tap do |socket|
          socket.setsockopt(:linger, 0)
          socket.bind('inproc://send-receive')
        end
      end

      before do
        sender.connect(receiver.getsockopt(:last_endpoint))
      end

      after do
        unless context.destroyed?
          sender.close unless sender.closed?
          receiver.close unless receiver.closed?
        end
      end

      describe '#send' do
        it 'sends string' do
          sender.send('hello')
          receiver.recv(5).should == 'hello'
        end

        it 'is possible to send multipart messages' do
          sender.send('hello', :sndmore)
          sender.send(' world')
          receiver.recv(5).should == 'hello'
          receiver.getsockopt(:rcvmore).should be_true
          receiver.recv(6).should == ' world'
          receiver.getsockopt(:rcvmore).should be_false
        end

        it 'is possible to send multipart messages in non-blocking mode' do
          sender.send('hello', :sndmore, :dontwait)
          sender.send(' world')
          receiver.recv(5).should == 'hello'
          receiver.getsockopt(:rcvmore).should be_true
          receiver.recv(6).should == ' world'
          receiver.getsockopt(:rcvmore).should be_false
        end

        it 'raises ArgumentError for unknown send options' do
          expect { sender.send('', :unknown) }.to raise_error(ArgumentError)
        end

        it 'raises InvalidStateError when socket is in wrong state' do
          sender.send('')
          expect { sender.send('') }.to raise_error(InvalidStateError)
        end

        it "raises TermError and closes socket if context has been destroyed" do
          receiver.close
          t = Thread.new { context.destroy }
          Thread.pass
          expect { sender.send('') }.to raise_error(TermError)
          t.join
          expect { sender.close }.to raise_error(Errno::ENOTSOCK)
        end
      end

      describe '#recv' do
        it 'receives specified number of bytes' do
          sender.send('hello')
          receiver.recv(3).should == 'hel'
        end

        it 'raises ArgumentError for unknown recv options' do
          expect { socket.recv('', :unknown) }.to raise_error(ArgumentError)
        end

        it 'raises EAGAIN if in non-blocking mode and there are no available messages' do
          expect { receiver.recv(1, :dontwait) }.to raise_error(Errno::EAGAIN)
        end

        it 'raises InvalidStateError when socket is in wrong state' do
          sender.send('')
          receiver.recv(1)
          expect { receiver.recv(1) }.to raise_error(InvalidStateError)
        end

        it "raises TermError and closes socket if context has been destroyed" do
          sender.close
          t = Thread.new { context.destroy }
          Thread.pass
          expect { receiver.recv(1) }.to raise_error(TermError)
          t.join
          expect { receiver.close }.to raise_error(Errno::ENOTSOCK)
        end
      end
    end

    describe '#close' do
      it 'closes the socket' do
        socket.close
        expect { socket.close }.to raise_error(Errno::ENOTSOCK)
      end
    end

    describe '#closed?' do
      it 'returns true if the socket has been closed' do
        socket.close
        socket.should be_closed
      end

      it "returns false if the socket hasn't been closed" do
        socket.should_not be_closed
      end
    end

    describe '#disconnect' do
      before do
        socket.connect('tcp://127.0.0.1:7788')
      end

      it 'raises EAGAIN when not connected to specified endpoint' do
        expect { socket.disconnect('tcp://127.0.0.1:7799') }.to raise_error(Errno::EAGAIN)
      end

      it "doesn't raise error when connected to specified socket" do
        expect { socket.disconnect('tcp://127.0.0.1:7788') }.not_to raise_error
      end

      term_error { socket.disconnect('tcp://127.0.0.1:7788') }
    end

    describe '#unbind' do
      before do
        socket.bind('tcp://127.0.0.1:7788')
      end

      it 'raises EAGAIN when not bound to specified endpoint' do
        expect { socket.unbind('tcp://127.0.0.1:7799') }.to raise_error(Errno::EAGAIN)
      end

      it "doesn't raise error when connected to specified socket" do
        expect { socket.unbind('tcp://127.0.0.1:7788') }.not_to raise_error
      end

      term_error { socket.unbind('tcp://0.0.0.0:7788') }
    end
  end
end

