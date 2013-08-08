require 'spec_helper'
require 'tempfile'

module Bundesstrasse
  describe Poller do
    let :poller do
      described_class.new
    end

    let :context do
      Context.create
    end

    let :file_handle do
      Tempfile.new('temp')
    end

    let! :rep_socket do
      context.rep_socket.tap do |s|
        s.bind('inproc://poller_spec')
      end
    end

    let! :req_socket do
      context.req_socket.tap do |s|
        s.connect('inproc://poller_spec')
      end
    end

    after do
      file_handle.close
      file_handle.unlink
    end

    describe '#register' do
      it 'registers for both pollin and pollout unless otherwise specified' do
        poller.register(rep_socket)
        req_socket.write('') # make rep readable
        res = poller.poll(0)
        res.readables.should include(rep_socket)
        rep_socket.read
        res = poller.poll(0)
        res.writables.should include(rep_socket)
      end

      it 'is possible to re-register for other event' do
        req_socket.write('')
        poller.register(rep_socket, :pollin)
        res = poller.poll(0)
        res.readables.should include(rep_socket)
        poller.register(rep_socket, :pollout)
        poller.poll(0).should be_none
        rep_socket.read
        res = poller.poll(0)
        res.writables.should include(rep_socket)
      end

      it 'is possible to register file handles' do
        if RUBY_PLATFORM == 'java'
          pending 'not available for JRuby yet'
        else
          poller.register(file_handle)
          res = poller.poll(0)
          res.readables.should include(file_handle)
        end
      end
    end

    describe '#unregister' do
      it 'no longer considers pollable' do
        poller.register(req_socket)
        res = poller.poll(0)
        res.writables.should include(req_socket)
        poller.unregister(req_socket)
        poller.poll(0).should be_none
      end
    end

    describe '#poll' do
      it "returns a #{described_class::Accessibles}" do
        poller.poll(0).should be_a(described_class::Accessibles)
      end
    end

    describe described_class::Accessibles do
      before do
        poller.register(rep_socket)
        poller.register(req_socket)
      end

      describe '#any?' do
        it 'returns true if there are any accessible items' do
          poller.poll(0).any?.should be_true
        end

        it "returns false if there aren't any accessible items" do
          poller.unregister(req_socket)
          poller.poll(0).any?.should be_false
        end
      end

      describe '#writables' do
        it 'returns writable items' do
          res = poller.poll(0)
          res.writables.should include(req_socket)
        end

        it 'returns empty array if none are writable' do
          req_socket.write('')
          res = poller.poll(0)
          res.writables.should be_empty
        end
      end

      describe '#readables' do
        it 'returns empty array if none are readable' do
          res = poller.poll(0)
          res.readables.should be_empty
        end

        it 'returns readable items' do
          req_socket.write('')
          res = poller.poll(0)
          res.readables.should include(rep_socket)
        end
      end
    end
  end
end
