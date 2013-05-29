require 'spec_helper'

module Bundesstrasse
  describe Context do

    let(:socket) { double('socket') }

    let(:zmq_socket) { double('zmq_socket') }

    subject { described_class.create }

    describe '#socket' do
      it 'raises ContextError if context has been terminated' do
        subject.terminate!
        expect { subject.socket(:req) }.to raise_error(ContextError)
      end

      it 'raises ContextError if unable to create socket' do
        ZMQ::Socket.stub(new: nil)
        expect { subject.socket(:req) }.to raise_error(ContextError)
      end

      it 'creates an instance of the specified socket type, when the type is a ZMQ constant' do
        ZMQ::Socket.should_receive(:new).with(anything, ZMQ::REQ).and_return(zmq_socket)
        subject.socket(:req)
      end

      it 'creates an instance of the specified socket type, when the type is a symbol' do
        ZMQ::Socket.should_receive(:new).with(anything, ZMQ::PUB).and_return(zmq_socket)
        subject.socket(:pub)
      end

      it 'creates an instance of the specified socket type, when the type is encoded in the method name' do
        ZMQ::Socket.should_receive(:new).with(anything, ZMQ::PUB).and_return(zmq_socket)
        subject.pub_socket
      end

      it 'wraps the ZMQ socket in a Bundesstrasse socket' do
        ZMQ::Socket.stub(:new).with(anything, ZMQ::REQ).and_return(zmq_socket)
        zmq_socket.should_receive(:connect).with('test').and_return(0)
        wrapper_socket = subject.socket(ZMQ::REQ)
        wrapper_socket.connect('test')
      end

      %w[SUB XSUB].each do |sub_type|
        it "wraps #{sub_type} sockets in a special wrapper that has helpers for #subscribe and #unsubscribe" do
          socket_type = ZMQ.const_get(sub_type)
          ZMQ::Socket.stub(:new).with(anything, socket_type).and_return(zmq_socket)
          wrapper_socket = subject.socket(socket_type)
          wrapper_socket.should respond_to(:subscribe)
          wrapper_socket.should respond_to(:unsubscribe)
        end
      end
    end

    describe '#terminate!' do
      it 'terminates ZMQ context' do
        subject.should_not be_terminated
        subject.terminate!
        subject.should be_terminated
      end
    end
  end
end
