require 'spec_helper'

module Bundesstrasse
  describe Socket do
    let(:zmq_socket) { double('socket').tap { |d| d.stub(setsockopt: 0, close: 0, socket: :pointer, connect: 0) } }

    subject { described_class.new(zmq_socket) }

    describe '#initialize' do
      it 'sets provided options on ZMQ socket' do
        zmq_socket.should_receive(:setsockopt).with(ZMQ::LINGER, 0).and_return(0)
        zmq_socket.should_receive(:setsockopt).with(ZMQ::SNDBUF, 10).and_return(0)
        described_class.new(zmq_socket, sndbuf: 10, linger: 0)
      end
    end

    describe '#socket' do
      it 'exposes pointer to ZMQ socket' do
        subject.pointer.should == :pointer
      end
    end

    [:bind, :connect].each do |method|
      describe "##{method}" do
        it 'raises SocketError on failure' do
          zmq_socket.stub(method).and_return(-1)
          expect { subject.send(method,'') }.to raise_error(SocketError)
        end
      end
    end

    {read: :recv_string, write: :send_string}.each do |method, zmq_method|
      describe "##{method}" do
        context 'when not connected/bound' do
          it 'raises SocketError unless connected/bound' do
            zmq_socket.stub(zmq_method).and_return(0)
            expect { subject.send(method, '') }.to raise_error(SocketError)
          end
        end

        context 'when connected/bound' do
          before do
            zmq_socket.stub(:connect).and_return(0)
            subject.connect('')
          end

          it "raises SocketError when #{zmq_method} fails" do
            zmq_socket.stub(zmq_method => -1)
            expect { subject.send(method, '') }.to raise_error(SocketError)
          end

          it 'raises AgainError when resource is temporarily unavailable' do
            subject.stub(errno: 35)
            zmq_socket.stub(zmq_method => -1)
            expect { subject.send(method, '') }.to raise_error(AgainError)
          end

          it 'raises TermError when context is terminated' do
            subject.stub(errno: 156384765)
            zmq_socket.stub(zmq_method => -1)
            expect { subject.send(method, '') }.to raise_error(TermError)
          end

          it 'closes socket when context is terminated' do
            subject.stub(errno: 156384765)
            zmq_socket.stub(zmq_method => -1)
            zmq_socket.should_receive(:close)
            expect { subject.send(method, '') }.to raise_error(TermError)
          end

          it "doesn't always raise error" do
            zmq_socket.stub(zmq_method).and_return(0)
            expect { subject.send(method,'') }.not_to raise_error(SocketError)
          end
        end
      end
    end

    describe '#read_multipart' do
      before do
        subject.connect('')
      end

      it 'returns a list of all parts of a multipart message' do
        parts = %w[hello world !]
        zmq_socket.stub(:more_parts?).and_return(true, true, false)
        zmq_socket.stub(:recv_string) { |buffer| buffer.replace(parts.shift); 0 }
        subject.read_multipart.should == %w[hello world !]
      end
    end

    describe '#write_multipart' do
      before do
        subject.connect('')
      end

      it 'sends a list of strings as a multipart message' do
        zmq_socket.should_receive(:send_string).with('hello', ZMQ::SNDMORE).and_return(0)
        zmq_socket.should_receive(:send_string).with('world', 0).and_return(0)
        subject.write_multipart('hello', 'world')
      end
    end

    describe '#more_parts?' do
      before do
        subject.connect('')
      end

      it 'forwards the call to the socket' do
        zmq_socket.stub(:more_parts?).and_return(true)
        subject.more_parts?.should be_true
        zmq_socket.stub(:more_parts?).and_return(false)
        subject.more_parts?.should be_false
      end
    end

    describe '#connected?' do
      it 'returns true if connected' do
        subject.connect('')
        subject.should be_connected
      end

      it 'returns false if not connected' do
        subject.should_not be_connected
      end
    end

    describe '#close!' do
      it 'closes the socket' do
        zmq_socket.should_receive(:close)
        subject.close!
      end

      it "doesn't raise error when not connected/bound" do
        expect { subject.close! }.not_to raise_error
      end
    end

    describe '.type' do
      it 'raises NotImplementedError unless overridden' do
        expect { described_class.type }.to raise_error(NotImplementedError)
      end
    end
  end
end
