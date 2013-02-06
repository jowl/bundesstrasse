require 'spec_helper'

module Bundesstrasse
  describe Socket do
    let(:socket) { double('socket').tap { |d| d.stub(setsockopt: 0) } }
    let(:context) { double('context').tap { |d| d.stub(socket: socket) } }

    before do
      Context.stub(:context).and_return(context)
    end

    subject { described_class.new(0) }

    describe '#initialize' do
      it 'sets provided options on socket' do
        socket.should_receive(:setsockopt).with(ZMQ::LINGER, 0).and_return(0)
        socket.should_receive(:setsockopt).with(ZMQ::SNDBUF, 10).and_return(0)
        described_class.new(0, sndbuf: 10, linger: 0)
      end

      it 'sets default options on socket' do
        socket.should_receive(:setsockopt).with(ZMQ::LINGER, 0).and_return(0)
        socket.should_receive(:setsockopt).with(ZMQ::SNDTIMEO, -1).and_return(0)
        socket.should_receive(:setsockopt).with(ZMQ::RCVTIMEO, -1).and_return(0)
        described_class.new(0)
      end
    end

    [:bind, :connect].each do |method|
      describe "##{method}" do
        it 'raises SocketError on failure' do
          socket.stub(method).and_return(-1)
          expect { subject.send(method,'') }.to raise_error(SocketError)
        end
      end
    end
    
    {read: :recv_string, write: :send_string}.each do |method, zmq_method|
      describe "##{method}" do
        context 'when not connected/bound' do
          it 'raises SocketError unless connected/bound' do
            socket.stub(zmq_method).and_return(0)
            expect { subject.send(method, '') }.to raise_error(SocketError)
          end
        end

        context 'when connected/bound' do
          before do
            socket.stub(:connect).and_return(0)
            subject.connect('')
          end

          it "raises SocketError when #{zmq_method} fails" do
            socket.stub(zmq_method => -1)
            expect { subject.send(method, '') }.to raise_error(SocketError)
          end

          it 'raises AgainError when resource is temporarily unavailable' do
            subject.stub(errno: 35)
            socket.stub(zmq_method => -1)
            expect { subject.send(method, '') }.to raise_error(AgainError)
          end

          it 'raises TermError when context is terminated' do
            subject.stub(errno: 156384765)
            socket.stub(zmq_method => -1)
            expect { subject.send(method, '') }.to raise_error(TermError)
          end

          it "doesn't always raise error" do
            socket.stub(zmq_method).and_return(0)
            expect { subject.send(method,'') }.not_to raise_error(SocketError)
          end
        end
      end
    end
  end
end
