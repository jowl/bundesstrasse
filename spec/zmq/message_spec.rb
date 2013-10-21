require 'spec_helper'

module ZMQ
  describe Message do
    let :message do
      described_class.new
    end

    after do
      message.close unless message.closed?
    end

    describe '::new' do
      it 'constructs an empty message without arguments' do
        message = described_class.new
        message.size.should == 0
        message.close
      end

      it 'constructs a message with provided argument' do
        message = described_class.new('payload')
        message.data.should == 'payload'
        message.close
      end
    end

    describe '#close' do
      it 'is idempotent' do
        message.close
        expect { message.close }.not_to raise_error
      end
    end

    describe '#closed?' do
      it 'returns true if the context has been closed' do
        message.close
        message.should be_closed
      end

      it "returns false if the message hasn't been closed" do
        message.should_not be_closed
      end
    end

    describe '#data' do
      it 'returns the payload' do
        message = described_class.new('payload')
        message.data.should == 'payload'
        message.close
      end
    end

    describe '#recv' do
      let :message do
        described_class.new('payload')
      end

      let :context do
        Context.new
      end

      let :socket do
        context.socket(:rep)
      end

      let :sender do
        context.socket(:req).tap do |socket|
          socket.setsockopt(:linger, 0)
          socket.bind('inproc://sender')
        end
      end

      after do
        message.close unless message.closed?
        unless context.destroyed?
          socket.close unless socket.closed?
          sender.close unless sender.closed?
          context.destroy
        end
      end

      it 'receives message' do
        socket.connect(sender.getsockopt(:last_endpoint))
        message.send(sender)
        message.data.should be_empty
        message.recv(socket)
        message.data.should == 'payload'
      end

      it 'is possible to receive multipart messages' do
        socket.connect(sender.getsockopt(:last_endpoint))
        message.send(sender, :sndmore)
        message.send(sender)
        message.recv(socket)
        message.more.should be_true
        message.recv(socket)
        message.more.should be_false
      end

      it 'is possible to receive multipart messages in non-blocking mode' do
        expect { message.send(sender, :sndmore, :dontwait) }.to raise_error(Errno::EAGAIN)
        socket.connect(sender.getsockopt(:last_endpoint))
        t0 = Time.now
        begin
          message.send(sender, :sndmore, :dontwait)
        rescue Errno::EAGAIN
          retry if Time.now - t0 < 1
          fail "couldn't send message"
        end
        message.send(sender)
        message.recv(socket)
        message.more.should be_true
        message.recv(socket)
        message.more.should be_false
      end

      it 'replaces old message upon receiving new' do
        socket.connect(sender.getsockopt(:last_endpoint))
        another_message = described_class.new('another payload')
        another_message.send(sender)
        another_message.close
        message.recv(socket)
        message.data.should == 'another payload'
      end

      it 'raises ArgumentError for unknown send options' do
        expect { message.recv(socket, :unknown) }.to raise_error(ArgumentError)
      end

      it 'raises EAGAIN if in non-blocking mode and there are no available messages' do
        expect { message.recv(socket, :dontwait) }.to raise_error(Errno::EAGAIN)
      end

      it 'raises InvalidStateError when socket is in wrong state' do
        socket.connect(sender.getsockopt(:last_endpoint))
        message.send(sender)
        message.recv(socket)
        expect { message.recv(socket) }.to raise_error(InvalidStateError)
      end

      it 'raises TermError and closes socket if context has been destroyed' do
        socket.connect('tcp://127.0.0.1:7788')
        t = Thread.new { context.destroy }
        Thread.pass
        expect { message.recv(socket) }.to raise_error(TermError)
        t.join
        expect { socket.close }.to raise_error(Errno::ENOTSOCK)
      end
    end

    describe '#send' do
      let :message do
        described_class.new('payload')
      end

      let :context do
        Context.new
      end

      let :socket do
        context.socket(:req).tap do |socket|
          socket.setsockopt(:linger, 0)
        end
      end

      let :receiver do
        context.socket(:rep).tap do |socket|
          socket.bind('inproc://receiver')
        end
      end

      after do
        message.close unless message.closed?
        unless context.destroyed?
          socket.close unless socket.closed?
          receiver.close unless receiver.closed?
          context.destroy
        end
      end

      it 'sends message' do
        socket.connect(receiver.getsockopt(:last_endpoint))
        message.send(socket)
        message.data.should be_empty
        message.recv(receiver)
        message.data.should == 'payload'
      end

      it 'is possible to send multipart messages' do
        socket.connect(receiver.getsockopt(:last_endpoint))
        message.send(socket, :sndmore)
        message.send(socket) # send final part
        message.recv(receiver)
        message.more.should be_true
      end

      it 'clears message upon sending it' do
        socket.connect('tcp://127.0.0.1:7788')
        message.send(socket)
        message.size.should == 0
        message.data.should == ''
      end

      it 'raises ArgumentError for unknown send options' do
        expect { message.send(socket, :unknown) }.to raise_error(ArgumentError)
      end

      it 'raises EAGAIN if in non-blocking mode and not able to send' do
        expect { message.send(socket, :dontwait) }.to raise_error(Errno::EAGAIN)
      end

      it 'raises InvalidStateError when socket is in wrong state' do
        socket.connect('tcp://127.0.0.1:7788')
        message.send(socket)
        expect { message.send(socket) }.to raise_error(InvalidStateError)
      end

      it 'raises TermError and closes socket if context has been destroyed' do
        socket = context.socket(:dealer).tap do |socket|
          socket.setsockopt(:linger, 0)
        end
        socket.connect('tcp://127.0.0.1:7788')
        t = Thread.new { context.destroy }
        send_loop = proc do
          t0 = Time.now
          until Time.now - t0 > 1
            message.send(socket)
          end
        end
        expect(send_loop).to raise_error(TermError)
        t.join
        expect { socket.close }.to raise_error(Errno::ENOTSOCK)
      end
    end

    describe '#size' do
      it 'returns the bytesize of the payload' do
        message = described_class.new('payload')
        message.size.should == 'payload'.bytesize
        message.close
      end
    end

    describe '#more' do
      let :context do
        Context.new
      end

      let :sender do
        context.socket(:req).tap do |socket|
          socket.setsockopt(:linger, 0)
        end
      end

      let :receiver do
        context.socket(:rep).tap do |socket|
          socket.bind('inproc://receiver')
        end
      end

      after do
        sender.close
        receiver.close
        context.destroy
      end

      it 'returns false if it is the final (or only) message part' do
        message.more.should be_false
      end

      it 'returns true if there are more message parts left' do
        sender.connect(receiver.getsockopt(:last_endpoint))
        message.send(sender, :sndmore)
        message.send(sender)
        message.recv(receiver)
        message.more.should be_true
      end
    end
  end
end

