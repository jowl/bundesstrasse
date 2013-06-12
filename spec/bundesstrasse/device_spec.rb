require 'spec_helper'

module Bundesstrasse
  describe Device do

    let(:frontend) { double('socket').tap { |s| s.stub(pointer: :pointer, close!: 0) } }
    let(:backend) { double('socket').tap { |s| s.stub(pointer: :pointer, close!: 0) } }

    subject { described_class.new(frontend, backend) }

    describe '#start' do
      before do
        LibZMQ.stub(errno: 156384765)
        LibZMQ.stub(zmq_proxy: -1)
      end

      it 'starts device using libzmq#zmq_device' do
        LibZMQ.should_receive(:zmq_proxy).with(:pointer, :pointer, nil).and_return(-1)
        subject.start
      end

      it 'closes both sockets on termination' do
        [frontend,backend].map { |s| s.should_receive(:close!).and_return(0) }
        subject.start
      end

      it 'raises DeviceError on unexpected termination' do
        LibZMQ.stub(errno: 0)
        expect { subject.start }.to raise_error(DeviceError)
      end
    end
  end
end
