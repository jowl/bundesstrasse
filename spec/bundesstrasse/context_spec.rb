require 'spec_helper'

module Bundesstrasse
  describe Context do
    let :context do
      described_class.new
    end

    after do
      context.destroy
    end

    describe '::new' do
      it 'raises ArgumentError for unknown options' do
        expect { described_class.new(unknown: 10) }.to raise_error(ArgumentError)
      end
    end

    describe '#destroy' do
      it 'is idempotent' do
        3.times { context.destroy }
        context.should be_destroyed
      end
    end

    describe '#destroyed?' do
      it 'returns true if the context has been destroyed' do
        context.destroy
        context.should be_destroyed
      end

      it "returns false if the context hasn't been destroyed" do
        context.should_not be_destroyed
      end
    end

    ZMQ::LibZMQ::SOCKET_TYPES.symbols.each do |type|
      describe "##{type}_socket" do
        it 'returns a Socket' do
          socket = context.send("#{type}_socket")
          socket.should be_a(Socket)
          socket.close
        end

        it "specifically a #{type} socket" do
          socket = context.send("#{type}_socket")
          socket.type.should == type
          socket.close
        end
      end
    end
  end
end
