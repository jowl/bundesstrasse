require 'spec_helper'

module ZMQ
  describe Context do
    let :context do
      described_class.new
    end

    after do
      context.destroy unless context.destroyed?
    end

    describe '#set/#get' do
      [:io_threads, :max_sockets].each do |option_name|
        it "sets and gets #{option_name}" do
          context.set(option_name, 101)
          context.get(option_name).should == 101
        end
      end

      it 'raises ArgumentError for unknown options' do
        expect { context.set(:unknown, '') }.to raise_error(ArgumentError)
        expect { context.get(:unknown) }.to raise_error(ArgumentError)
      end

      it 'raises EINVAL when setting invalid property values' do
        expect { context.set(:io_threads, -1) }.to raise_error(Errno::EINVAL)
      end
    end

    describe '#destroy' do
      it 'raises EFAULT if called more than once' do
        context.destroy
        expect { context.destroy }.to raise_error(Errno::EFAULT)
      end
    end

    describe '#destroyed?' do
      it 'returns true if Context has been destroyed' do
        context.destroy
        context.should be_destroyed
      end

      it "returns false if Context hasn't been destroyed" do
        context.should_not be_destroyed
      end
    end

    describe '#socket' do
      it "returns an instance of #{Socket}" do
        socket = context.socket(:req)
        socket.should be_a(Socket)
        socket.close
      end

      it 'raises ArgumentError for unknown socket types' do
        expect { context.socket(:unknown) }.to raise_error(ArgumentError)
      end

      it 'raises EMFILE if the total number of open sockets have been reached' do
        context.set(:max_sockets, 1)
        socket = context.socket(:req)
        expect { context.socket(:req) }.to raise_error(Errno::EMFILE)
        socket.close
      end
    end
  end
end

