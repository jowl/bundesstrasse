require 'spec_helper'

module Bundesstrasse
  describe Context do

    let(:type) { 1 }
    let(:socket) { double('socket') }
    let(:socket_class) do
      double('socket_class').tap { |s| s.stub(new: socket, type: type) }
    end

    let(:zmq_socket) { double('socket') }
    let(:zmq_context) do
      double('context').tap do |s|
        s.stub(socket: zmq_socket, context: true)
        s.stub(:term) { s.stub(context: nil) }
      end
    end

    subject { described_class.new(zmq_context) }

    describe '#socket' do
      it 'raises ContextError if context has been terminated' do
        subject.terminate!
        expect { subject.socket(socket_class) }.to raise_error(ContextError)
      end

      it 'raises ContextError if unable to create socket' do
        zmq_context.stub(:socket).and_raise(JZMQ::ZMQException.new('',-1))
        expect { subject.socket(socket_class) }.to raise_error(ContextError)
      end

      it 'creates an instance of the provided socket class' do
        socket_class.should_receive(:new).with(zmq_socket, anything).and_return(socket)
        subject.socket(socket_class)
      end

      it 'uses #type on socket class to determine ZMQ socket' do
        zmq_context.should_receive(:socket).with(type)
        subject.socket(socket_class)
      end
    end

    describe '#terminate!' do
      it 'terminates ZMQ context' do
        zmq_context.should_receive(:term)
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

    describe '#context' do
      it 'exposes the wrapped context' do
        subject.context.should == zmq_context
      end
    end

    describe '.create' do
      it 'creates a context from an actual ZMQ context' do
        JZMQ::ZMQ.should_receive(:context).and_call_original
        context = described_class.create
        context.class.should == described_class
        context.terminate!
      end
    end
  end
end
