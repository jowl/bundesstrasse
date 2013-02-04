require 'spec_helper'

module BZMQ
  describe Context do

    after do
      described_class.instance_variable_set(:@context,nil)
      described_class.instance_variable_set(:@io_threads,nil)
    end

    describe '.context' do
      it 'creates one context only' do
        context = described_class.context
        described_class.context.should == context
      end

      it 'raises error if called with different argument' do
        described_class.context(10)
        expect { described_class.context(11) }.to raise_error(ContextError)
      end
    end
  end
end
