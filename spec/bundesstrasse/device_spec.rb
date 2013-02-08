require 'spec_helper'

module Bundesstrasse
  describe Device do

    let(:type) { 1 }
    let(:frontend) { double('socket').tap { |s| s.stub(pointer: :pointer, close: 0) } }
    let(:backend) { double('socket').tap { |s| s.stub(pointer: :pointer, close: 0) } }

    subject { described_class.new(type, frontend, backend) }

    describe '#start' do
      before do
        ZMQ::Util.stub(errno: 156384765)
        ZMQ::LibZMQ.stub(zmq_device: -1)
      end

      it 'starts device using libzmq#zmq_device' do
        ZMQ::LibZMQ.should_receive(:zmq_device).with(type, :pointer, :pointer).and_return(-1)
        subject.start
      end

      it 'closes both sockets on termination' do
        [frontend,backend].map { |s| s.should_receive(:close).and_return(0) }
        subject.start
      end

      it 'raises DeviceError on unexpected termination' do
        ZMQ::Util.stub(errno: -1)
        expect { subject.start }.to raise_error(DeviceError)
      end
    end
  end
end
