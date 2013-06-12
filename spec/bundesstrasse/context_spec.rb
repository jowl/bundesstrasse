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
        LibZMQ.stub(zmq_socket: nil)
        expect { subject.socket(:req) }.to raise_error(ContextError)
      end

      it 'creates an instance of the specified socket type, when the type is a constant' do
        subject.socket(3).type.should == :req
      end

      it 'creates an instance of the specified socket type, when the type is a symbol' do
        subject.socket(:pub).type.should == :pub
      end

      it 'creates an instance of the specified socket type, when the type is encoded in the method name' do
        subject.sub_socket.type.should == :sub
      end

      [:sub, :xsub].each do |socket_type|
        it "wraps #{socket_type} sockets in a special wrapper that has helpers for #subscribe and #unsubscribe" do
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
