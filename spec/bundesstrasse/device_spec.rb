require 'spec_helper'

module Bundesstrasse
  describe Device do

    let(:device) { double('device').tap { |s| s.stub(run: nil) } }
    let(:frontend) { double('socket').tap { |s| s.stub(close!: true) } }
    let(:backend) { double('socket').tap { |s| s.stub(close!: true) } }

    subject { described_class.new(device, frontend, backend) }

    describe '#start' do
      it 'closes both sockets on termination' do
        device.stub(:run).and_raise(JZMQ::ZMQException.new('',JZMQ::ZMQ.ETERM))
        [frontend,backend].map { |s| s.should_receive(:close!) }
        subject.start
      end

      it 'raises DeviceError on unexpected termination' do
        device.stub(:run).and_raise(JZMQ::ZMQException.new('',-1))
        expect { subject.start }.to raise_error(DeviceError)
      end
    end
  end
end
