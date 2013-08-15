require 'spec_helper'

module Bundesstrasse
  module ZMQ
    describe Proxy do

      let :context do
        Context.new
      end

      let :frontend do
        context.socket(:router)
      end

      let :backend do
        context.socket(:dealer)
      end

      let! :proxy do
        described_class.new(frontend, backend)
      end

      after do
        frontend.close rescue nil
        backend.close rescue nil
        context.destroy rescue nil
      end

      describe '#start' do
        it 'closes frontend and backend sockets on termination' do
          t = Thread.new { context.destroy }
          Thread.pass
          proxy.start
          [frontend, backend].each do |socket|
            expect { socket.close }.to raise_error(Errno::ENOTSOCK)
          end
          t.join
        end
      end
    end
  end
end
