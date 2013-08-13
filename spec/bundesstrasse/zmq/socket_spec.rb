require 'spec_helper'

module Bundesstrasse
  module ZMQ
    describe Socket do
      let :context do
        Context.new
      end

      let! :socket do
        context.socket(:req).tap { |s| s.setsockopt(:linger, 0) }
      end

      after do
        socket.close rescue nil
        context.destroy rescue nil
      end

      def self.term_error(&block)
        it "raises TermError and closes socket if context has been destroyed" do
          t = Thread.new { context.destroy }
          Thread.pass
          expect { instance_exec(&block) }.to raise_error(TermError)
          t.join
          expect { socket.close }.to raise_error(Errno::ENOTSOCK)
        end
      end

      describe '#bind' do
        it 'binds to the specified endpoint' do
          socket.bind('tcp://0.0.0.0:7788')
          socket.getsockopt(:last_endpoint).should == 'tcp://0.0.0.0:7788'
        end

        it 'raises EPROTONOSUPPORT for unsupported protocols' do
          expect { socket.bind('smtp://0.0.0.0:7788') }.to raise_error(Errno::EPROTONOSUPPORT)
        end

        it 'raises EINVAL for invalid address' do
          expect { socket.bind('this-is-not-a-valid-endpoint') }.to raise_error(Errno::EINVAL)
        end

        it 'raises EADDRINUSE when binding to same address more than once' do
          socket.bind('tcp://0.0.0.0:7788')
          expect { socket.bind('tcp://0.0.0.0:7788') }.to raise_error(Errno::EADDRINUSE)
        end

        it 'raises ENODEV for non-existent interfaces' do
          expect { socket.bind('tcp://this-endpoint-does-not-exist:7788') }.to raise_error(Errno::ENODEV)
        end

        term_error { socket.bind('tcp://0.0.0.0:7788') }
      end

      describe '#connect' do
        it 'connects to the specified endpoint' do
          socket.connect('tcp://127.0.0.1:7788')
          socket.getsockopt(:last_endpoint).should == 'tcp://127.0.0.1:7788'
        end

        it 'raises EPROTONOSUPPORT for unsupported protocols' do
          expect { socket.connect('smtp://127.0.0.1:7788') }.to raise_error(Errno::EPROTONOSUPPORT)
        end

        it 'raises EINVAL for invalid address' do
          expect { socket.connect('this-is-not-a-valid-endpoint') }.to raise_error(Errno::EINVAL)
        end

        term_error { socket.connect('tcp://127.0.0.1:7788') }
      end

      describe '#setsockopt/#getsockopt' do
        context 'with boolean options' do
          [:ipv4only, :delay_attach_on_connect].each do |option_name|
            it "sets and gets #{option_name}" do
              socket.setsockopt(option_name, 1)
              socket.getsockopt(option_name).should == 1
              socket.setsockopt(option_name, 0)
              socket.getsockopt(option_name).should == 0
            end
          end
        end

        context 'with numerical options' do
          [:affinity, :rate, :recovery_ivl, :sndbuf, :rcvbuf, :linger, :reconnect_ivl, :backlog, :reconnect_ivl_max, :maxmsgsize, :sndhwm, :rcvhwm, :multicast_hops, :rcvtimeo, :sndtimeo].each do |option_name|
            it "sets and gets #{option_name}" do
              socket.setsockopt(option_name, 101)
              socket.getsockopt(option_name).should == 101
            end
          end
        end

        context 'with string options' do
          it 'sets and gets identity' do
            socket.setsockopt(:identity, 'spec id')
            socket.getsockopt(:identity).should == 'spec id'
          end
        end

        it 'raises ArgumentError for unknown options' do
          expect { socket.setsockopt(:unknown, '') }.to raise_error(ArgumentError)
          expect { socket.getsockopt(:unknown) }.to raise_error(ArgumentError)
        end

        it 'raises EINVAL when setting invalid propery values' do
          expect { socket.setsockopt(:identity, '') }.to raise_error(Errno::EINVAL)
        end

        it 'raises ENOTSOCK when socket has been closed' do
          socket.close
          expect { socket.setsockopt(:ipv4only, 1) }.to raise_error(Errno::ENOTSOCK)
          expect { socket.getsockopt(:ipv4only) }.to raise_error(Errno::ENOTSOCK)
        end
      end

      describe '#close' do
        it 'closes the socket' do
          socket.close
          expect { socket.close }.to raise_error(Errno::ENOTSOCK)
        end
      end

      describe '#disconnect' do
        it 'raises EAGAIN when not connected to specified endpoint' do
          expect { socket.disconnect('tcp://127.0.0.1:7788') }.to raise_error(Errno::EAGAIN)
        end

        it "doesn't raises error when connected to specified socket" do
          socket.connect('tcp://127.0.0.1:7788')
          expect { socket.disconnect('tcp://127.0.0.1:7788') }.not_to raise_error
        end

        term_error { socket.disconnect('tcp://127.0.0.1:7788') }
      end

      describe '#unbind' do
        it 'raises EAGAIN when not bound to specified endpoint' do
          expect { socket.unbind('tcp://0.0.0.0:7788') }.to raise_error(Errno::EAGAIN)
        end

        it "doesn't raises error when connected to specified socket" do
          socket.bind('tcp://127.0.0.1:7788')
          expect { socket.unbind('tcp://127.0.0.1:7788') }.not_to raise_error
        end

        term_error { socket.unbind('tcp://0.0.0.0:7788') }
      end
    end
  end
end
