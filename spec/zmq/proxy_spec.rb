require 'spec_helper'

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

      it 'is possible to send messages through proxy' do
        frontend.bind('inproc://frontend')
        backend.bind('inproc://backend')
        t = Thread.new { proxy.start }
        client = context.socket(:req).tap { |s| s.connect(frontend.getsockopt(:last_endpoint)) }
        server = context.socket(:rep).tap { |s| s.connect(backend.getsockopt(:last_endpoint)) }
        request = Message.new('hello')
        request.send(client)
        request.recv(server)
        request.data.should == 'hello'
        reply = Message.new('world')
        reply.send(server)
        reply.recv(client)
        reply.data.should == 'world'
        [client, server, request, reply].each(&:close)
        context.destroy
        t.join
      end
    end
  end
end

