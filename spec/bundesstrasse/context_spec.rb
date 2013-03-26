require 'spec_helper'

module Bundesstrasse
  describe Context do

    let(:socket) { double('socket') }

    let(:zmq_socket) { double('zmq_socket') }
    let(:zmq_context) do
      double('context').tap do |s|
        s.stub(socket: zmq_socket, context: true)
        s.stub(:terminate) { s.stub(context: nil) }
      end
    end

    subject { described_class.new(zmq_context) }

    describe '#socket' do
      it 'raises ContextError if context has been terminated' do
        subject.terminate!
        expect { subject.socket(ZMQ::REQ) }.to raise_error(ContextError)
      end

      it 'raises ContextError if unable to create socket' do
        zmq_context.stub(socket: nil)
        expect { subject.socket(ZMQ::REQ) }.to raise_error(ContextError)
      end

      it 'creates an instance of the specified socket type, when the type is a ZMQ constant' do
        zmq_context.should_receive(:socket).with(ZMQ::REQ).and_return(zmq_socket)
        subject.socket(ZMQ::REQ)
      end

      it 'creates an instance of the specified socket type, when the type is a symbol' do
        zmq_context.should_receive(:socket).with(ZMQ::PUB).and_return(zmq_socket)
        subject.socket(:pub)
      end

      it 'creates an instance of the specified socket type, when the type is encoded in the method name' do
        zmq_context.should_receive(:socket).with(ZMQ::PUB).and_return(zmq_socket)
        subject.pub_socket
      end

      it 'wraps the ZMQ socket in a Bundesstrasse socket' do
        zmq_context.stub(:socket).with(ZMQ::REQ).and_return(zmq_socket)
        zmq_socket.should_receive(:connect).with('test').and_return(0)
        wrapper_socket = subject.socket(ZMQ::REQ)
        wrapper_socket.connect('test')
      end

      %w[SUB XSUB].each do |sub_type|
        it "wraps #{sub_type} sockets in a special wrapper that has helpers for #subscribe and #unsubscribe" do
          socket_type = ZMQ.const_get(sub_type)
          zmq_context.stub(:socket).with(socket_type).and_return(zmq_socket)
          wrapper_socket = subject.socket(socket_type)
          wrapper_socket.should respond_to(:subscribe)
          wrapper_socket.should respond_to(:unsubscribe)
        end
      end
    end

    describe '#terminate!' do
      it 'terminates ZMQ context' do
        zmq_context.should_receive(:terminate)
        subject.terminate!
      end
    end

    describe '#terminated?' do
      it "checks if ZMQ context's context is defined" do
        # contexts all the way down
        subject.should_not be_terminated
        subject.terminate!
        subject.should be_terminated
      end
    end

    describe '.create' do
      it 'creates a context from an actual ZMQ context' do
        ZMQ::Context.should_receive(:create).and_call_original
        context = described_class.create
        context.class.should == described_class
        context.terminate!
      end
    end
  end
end
