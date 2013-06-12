require 'ffi'

module Bundesstrasse
  module LibZMQ
    extend FFI::Library

    ffi_lib 'libzmq'

    # Constants
    SOCKET_TYPES = enum :socket_type,      [:pair, :pub, :sub, :req, :rep, :dealer, :router, :pull, :push, :xpub, :xsub]
    enum :socket_option,    [:affinity, 4, :identity, :subscribe, :unsubscribe, :rate, :recovery_ivl, :sndbuf, 11, :rcvbuf, :rcvmore, :fd, :events, :type, :linger, :reconnect_ivl, :backlog, :reconnect_ivl_max, 21, :maxmsgsize, :sndhwm, :rcvhwm, :multicast_hops, :rcvtimeo, 27, :sndtimeo, :ipv4only, 31, :last_endpoint, :router_mandatory, :tcp_keepalive, :tcp_keepalive_cnt, :tcp_keepalive_idle, :tcp_keepalive_intvl, :tcp_accept_filter, :immediate, :xpub_verbose, :router_raw, :ipv6, :mechanism, :plain_server, :plain_username, :plain_password, :curve_server, :curve_publickey, :curve_serverkey, :probe]
    enum :context_option,   [:io_threads, 1, :max_sockets]
    enum :send_recv_option, [:null, :dontwait, :sndmore]

    SOCKOPT_TYPES = { affinity: :long, backlog: :int, identity: :string, immediate: :int, ipv4only: :int, ipv6: :int, last_endpoint: :string, linger: :int, maxmsgsize: :long, mechanism: :int, multicast_hops: :int, plain_password: :string, plain_server: :int, plain_username: :string, rate: :int, rcvbuf: :int, rcvhwm: :int, rcvtimeo: :int, reconnect_ivl: :int, reconnect_ivl_max: :int, recovery_ivl: :int, sndbuf: :int, sndhwm: :int, sndtimeo: :int, tcp_accept_filter: :string, tcp_keepalive: :int, tcp_keepalive_cnt: :int, tcp_keepalive_idle: :int, tcp_keepalive_intvl: :int, type: :int }

    def self.setsockopt(socket, socket_option, value)
      case SOCKOPT_TYPES[socket_option]
      when :int then zmq_setsockopt_int(socket, socket_option, value)
      when :long then zmq_setsockopt_long(socket, socket_option, value)
      when :string then zmq_setsockopt_string(socket, socket_option, value)
      else raise ArgumentError, "Unknown socket option: #{socket_option}"
      end
    end

    def self.zmq_setsockopt_string(socket, socket_option, value)
      option_value = FFI::MemoryPointer.new value.bytesize, 1, true
      option_value.write_string value
      zmq_setsockopt(socket, socket_option, option_value, value.bytesize)
    end

    def self.zmq_setsockopt_int(socket, socket_option, value)
      option_value = FFI::MemoryPointer.new :int
      option_value.write_int value
      zmq_setsockopt(socket, socket_option, option_value, option_value.size)
    end

    def self.zmq_setsockopt_long(socket, socket_option, value)
      option_value = FFI::MemoryPointer.new :long_long
      option_value.write_long_long value
      zmq_setsockopt(socket, socket_option, option_value, option_value.size)
    end

    # Context API
    attach_function :zmq_ctx_destroy, [:pointer],                        :int,     blocking: true
    attach_function :zmq_ctx_get,     [:pointer, :context_option],       :int,     blocking: true
    attach_function :zmq_ctx_new,     [],                                :pointer, blocking: true
    attach_function :zmq_ctx_set,     [:pointer, :context_option, :int], :int,     blocking: true

    # Socket API
    attach_function :zmq_socket,     [:pointer, :socket_type],                       :pointer, blocking: true
    attach_function :zmq_bind,       [:pointer, :string],                            :int,     blocking: true
    attach_function :zmq_connect,    [:pointer, :string],                            :int,     blocking: true
    attach_function :zmq_getsockopt, [:pointer, :socket_option, :pointer, :pointer], :int,     blocking: true
    attach_function :zmq_setsockopt, [:pointer, :socket_option, :pointer, :size_t],  :int,     blocking: true
    attach_function :zmq_close,      [:pointer],                                     :int,     blocking: true
    attach_function :zmq_disconnect, [:pointer, :string],                            :int,     blocking: true
    attach_function :zmq_unbind,     [:pointer, :string],                            :int,     blocking: true

    # attach_function :zmq_recv, [:pointer, :pointer, :size_t, :int], :int, blocking: true
    # attach_function :zmq_send, [:pointer, :pointer, :size_t, :int], :int, blocking: true
    # attach_function :zmq_socket_monitor, [], :int, blocking: true

    # Message API
    attach_function :zmq_msg_close,     [:pointer],                                        :int,     blocking: true
    attach_function :zmq_msg_init,      [:pointer],                                        :int,     blocking: true
    attach_function :zmq_msg_init_data, [:pointer, :pointer, :size_t, :pointer, :pointer], :int,     blocking: true
    attach_function :zmq_msg_init_size, [:pointer, :size_t],                               :int,     blocking: true
    attach_function :zmq_msg_data,      [:pointer],                                        :pointer, blocking: true
    attach_function :zmq_msg_recv,      [:pointer, :pointer, :send_recv_option],           :int,     blocking: true
    attach_function :zmq_msg_send,      [:pointer, :pointer, :send_recv_option],           :int,     blocking: true
    attach_function :zmq_msg_size,      [:pointer],                                        :int,     blocking: true
    attach_function :zmq_msg_more,      [:pointer],                                        :int,     blocking: true

    def self.zmq_msg(payload=nil)
      msg = FFI::MemoryPointer.new 32, 1, false
      if payload
        zmq_msg_init_size(msg, payload.bytesize)
        zmq_msg_data(msg).write_string(payload)
      else
        zmq_msg_init(msg)
      end
      if block_given?
        yield msg
        zmq_msg_close(msg)
      else
        msg # don't forget to close message
      end
    end

    def self.zmq_msg_string(msg)
      zmq_msg_data(msg).read_string(zmq_msg_size(msg))
    end

    # attach_function :zmq_msg_copy, [], :int, blocking: true
    # attach_function :zmq_msg_get, [], :int, blocking: true
    # attach_function :zmq_msg_more, [], :int, blocking: true
    # attach_function :zmq_msg_move, [], :int, blocking: true
    # attach_function :zmq_msg_set, [], :int, blocking: true

    # Misc API
    def self.errno
      FFI.errno
    end

    attach_function :zmq_strerror, [:int], :pointer, blocking: true
    def self.strerror
      zmq_strerror(errno).read_string
    end
    # attach_function :zmq_errno, [], :int, blocking: true
    # attach_function :zmq_poll, [], :int, blocking: true
    # attach_function :zmq_proxy, [], :int, blocking: true
    # attach_function :zmq_version, [], :int, blocking: true

    # Deprecated API

    # attach_function :zmq_init, [], :int, blocking: true
    # attach_function :zmq_recvmsg, [], :int, blocking: true
    # attach_function :zmq_sendmsg, [], :int, blocking: true
    # attach_function :zmq_term, [], :int, blocking: true
  end

end
