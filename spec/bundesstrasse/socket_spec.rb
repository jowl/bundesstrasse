require 'spec_helper'

module Bundesstrasse
  describe Socket do
    let :zmq_socket do
      double('socket')
    end

    let! :context do
      Context.create
    end

    let :spec_endpoint do
      'inproc://spec_endpoint'
    end

    let! :socket1 do
      context.pair_socket.tap do |socket|
        socket.bind(spec_endpoint)
      end
    end

    let! :socket2 do
      context.pair_socket.tap do |socket|
        socket.connect(spec_endpoint)
      end
    end

    let :terminate_context do
      Thread.new { context.terminate! }
    end

    after do
      socket1.close! rescue nil
      socket2.close! rescue nil
      terminate_context.join
    end

    subject { described_class.new(zmq_socket) }

    describe '#initialize' do
      it 'sets provided options on ZMQ socket' do
        LibZMQ.should_receive(:setsockopt).with(zmq_socket, :linger, 0).and_return(0)
        LibZMQ.should_receive(:setsockopt).with(zmq_socket, :sndbuf, 10).and_return(0)
        described_class.new(zmq_socket, sndbuf: 10, linger: 0)
      end
    end

    describe '#socket' do
      it 'exposes pointer to ZMQ socket' do
        subject.pointer.should == zmq_socket
      end
    end

    [:bind, :connect].each do |method|
      describe "##{method}" do
        before do
          LibZMQ.stub(errno: 0)
          LibZMQ.stub(zmq_bind: -1, zmq_connect: -1)
        end

        it 'raises SocketError on failure' do
          expect { subject.send(method,'') }.to raise_error(SocketError)
        end
      end
    end

    {read: :zmq_msg_recv, write: :zmq_msg_send}.each do |method, zmq_method|
      describe "##{method}" do
        context 'when not connected/bound' do
          it 'raises SocketError unless connected/bound' do
            expect { subject.send(method, '') }.to raise_error(SocketError)
          end
        end

        context 'when connected/bound' do
          before do
            LibZMQ.stub(zmq_connect: 0)
            subject.connect('')
          end

          it "raises SocketError when #{zmq_method} fails" do
            LibZMQ.stub(zmq_method => -1)
            LibZMQ.stub(errno: 0)
            expect { subject.send(method, '') }.to raise_error(SocketError)
          end

          it 'raises AgainError when resource is temporarily unavailable' do
            socket = context.pair_socket(rcvtimeo: 0, sndtimeo: 0)
            socket.bind("#{spec_endpoint}_tmp")
            expect { socket.send(method, '') }.to raise_error(AgainError)
            socket.close!
          end

          it 'raises TermError when context is terminated' do
            terminate_context
            Thread.pass
            expect { socket1.send(method, '') }.to raise_error(TermError)
          end

          it 'closes socket when context is terminated' do
            terminate_context
            Thread.pass
            expect { socket1.send(method, '') }.to raise_error(TermError)
            expect { socket1.send(method, '') }.to raise_error(SocketError, /not connected/i)
          end

          it "doesn't always raise error" do
            socket1.write('')
            expect { socket2.send(method,'') }.not_to raise_error
          end
        end
      end
    end

    describe '#read_nonblocking' do
      before do
        LibZMQ.stub(zmq_connect: 0)
        subject.connect('')
      end

      it 'reads with the nonblocking flag set' do
        LibZMQ.should_receive(:zmq_msg_recv).with(anything, socket1.pointer, :dontwait).and_return(0)
        socket1.read_nonblocking
      end

      it 'raises AgainError if no message' do
        expect { socket1.read_nonblocking }.to raise_error(AgainError)
      end
    end

    describe '#write_nonblocking' do
      before do
        LibZMQ.stub(zmq_connect: 0)
        subject.connect('')
      end

      it 'writes with the nonblocking flag set' do
        LibZMQ.should_receive(:zmq_msg_send).with(anything, socket1.pointer, :dontwait).and_return(0)
        socket1.write_nonblocking('foo')
      end

      it 'raises AgainError if no receiver' do
        socket = context.pair_socket
        socket.bind("#{spec_endpoint}_tmp")
        expect { socket.write_nonblocking('foo') }.to raise_error(AgainError)
        socket.close!
      end
    end

    describe '#read/write_multipart' do
      it 'returns a list of all parts of a multipart message' do
        socket1.write_multipart('hello', 'world', '!')
        socket2.read_multipart.should == %w[hello world !]
      end
    end

    describe '#more_parts?' do
      it 'returns true if there are more messages on the wire' do
        socket1.write_multipart('one','two')
        socket2.read
        socket2.more_parts?.should be_true
        socket2.read
        socket2.more_parts?.should be_false
      end
    end

    describe '#connected?' do
      let :socket do
        context.pair_socket
      end

      after do
        socket.close!
      end

      it 'returns true if bound/connected' do
        socket.bind("#{spec_endpoint}_tmp")
        socket.should be_connected
      end

      it 'returns false if not bound/connected' do
        socket.should_not be_connected
      end
    end

    describe '#close!' do
      let :socket do
        context.pair_socket
      end

      it 'closes the socket' do
        socket.bind("#{spec_endpoint}_tmp")
        socket.close!
        expect { socket.read }.to raise_error(SocketError, /not connected/i)
      end

      it "doesn't raise error when not connected/bound" do
        expect { socket.close! }.not_to raise_error
      end
    end
  end

  describe SubSocket do
    let :zmq_socket do
      stub(:zmq_socket)
    end

    let :socket do
      described_class.new(zmq_socket)
    end

    before do
      LibZMQ.stub(zmq_connect: 0)
      socket.connect('')
    end

    describe '#subscribe' do
      it 'sets the subscribe option on the socket' do
        LibZMQ.should_receive(:zmq_setsockopt).with(zmq_socket, :subscribe, anything, anything).and_return(0)
        socket.subscribe('giraffes')
      end

      it 'raises errors when the socket returns errors' do
        LibZMQ.stub(errno: 0)
        LibZMQ.stub(zmq_setsockopt: -1)
        expect { socket.subscribe('giraffes') }.to raise_error(SocketError)
      end
    end

    describe '#unsubscribe' do
      it 'sets the unsubscribe option on the socket' do
        LibZMQ.should_receive(:zmq_setsockopt).with(zmq_socket, :unsubscribe, anything, anything).and_return(0)
        socket.unsubscribe('giraffes')
      end

      it 'raises errors when the socket returns errors' do
        LibZMQ.stub(errno: 0)
        LibZMQ.stub(zmq_setsockopt: -1)
        expect { socket.unsubscribe('giraffes') }.to raise_error(SocketError)
      end
    end
  end
end
