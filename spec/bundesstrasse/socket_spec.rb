require 'spec_helper'

module Bundesstrasse
  describe Socket do
    let :context do
      Context.new(io_threads: 0)
    end

    let :socket do
      context.pair_socket
    end

    let :endpoint do
      'inproc://socket-spec'
    end

    let :other_socket do
      context.pair_socket
    end

    before do
      socket.bind(endpoint)
      other_socket.connect(endpoint)
    end

    after do
      socket.close
      other_socket.close
      context.destroy
    end

    describe '::new' do
      let :zmq_socket do
        stub(:zmq_socket)
      end

      it 'sets socket options on provided socket' do
        zmq_socket.should_receive(:setsockopt).with(:linger, 0)
        described_class.new(zmq_socket, linger: 0)
      end
    end

    describe '#type' do
      it 'returns the type of the socket as a Symbol' do
        socket.type.should == :pair
      end
    end

    describe '#readable?' do
      it "returns false when there's nothing to read" do
        socket.should_not be_readable
      end

      it "returns true when at least one message can be read" do
        other_socket.send ''
        socket.should be_readable
      end
    end

    describe '#writable?' do
      it 'returns false when nothing can be sent without blocking' do
        socket = context.pair_socket
        socket.should_not be_writable
        socket.close
      end

      it 'returns true when something can be sent without blocking' do
        socket.should be_writable
      end
    end

    describe '#recv' do
      it "raises EAGAIN if there's nothing to read when called with :dontwait" do
        expect { socket.recv(:dontwait) }.to raise_error(Errno::EAGAIN)
      end
    end

    describe '#recv_multipart' do
      it 'returns all message parts in an Array' do
        other_socket.send('a', 'b', 'c')
        socket.recv_multipart.should == %w[a b c]
      end

      it "raises EAGAIN if there's nothing to read when called with :dontwait" do
        expect { socket.recv_multipart(:dontwait) }.to raise_error(Errno::EAGAIN)
      end
    end

    describe '#send' do
      it 'sends single string as single message' do
        socket.send('single')
        other_socket.recv.should == 'single'
        other_socket.should_not be_more
      end

      it 'sends multiple strings as multipart-message' do
        socket.send('multiple', 'strings')
        other_socket.recv.should == 'multiple'
        other_socket.should be_more
        other_socket.recv.should == 'strings'
      end

      it "raises EAGAIN if unable to send when called with :dontwait" do
        socket = context.pair_socket
        expect { socket.send('', :dontwait) }.to raise_error(Errno::EAGAIN)
        socket.close
      end
    end

    describe '#more?' do
      it 'returns false if there are no more parts to read' do
        other_socket.send('')
        socket.recv
        socket.should_not be_more
      end

      it 'returns true if there are more parts to read' do
        other_socket.send('', '')
        socket.recv
        socket.should be_more
      end
    end

    describe '#close' do
      it 'is idempotent' do
        3.times { socket.close }
        socket.should be_closed
      end
    end

    describe '#closed?' do
      it "returns false when socket hasn't been closed" do
        socket.should_not be_closed
      end

      it 'returns true when socket has been closed' do
        socket.close
        socket.should be_closed
      end
    end
  end
end
