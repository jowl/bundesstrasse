require 'ffi'

module Bundesstrasse
  module SocketOptionDsl
    SocketOption = Struct.new(:name, :num, :type)

    def sockopt(name, num, type)
      @sockopts ||= Hash.new { |_,k| raise ArgumentError, "Unknown socket option: #{k}" }
      @sockopts[name] = SocketOption.new(name, num, type)
    end

    def sockopts
      @sockopts
    end
  end

  module LibZMQ
    extend FFI::Library
    extend SocketOptionDsl

    ffi_lib 'libzmq'

    # Constants
    SOCKET_TYPES = enum :socket_type,      [:pair, :pub, :sub, :req, :rep, :dealer, :router, :pull, :push, :xpub, :xsub]
    enum :ctxopt,   [:io_threads, 1, :max_sockets]
    SEND_RECV_OPTS = enum :dontwait, 1, :sndmore
    EVENT_FLAGS = enum :poll_flags, [:pollin, 1, :pollout, :pollerr, 4]

    sockopt :affinity,                 4,  :ulong_long # set get
    sockopt :identity,                 5,  :bytes      # set get
    sockopt :subscribe,                6,  :bytes      # set
    sockopt :unsubscribe,              7,  :bytes      # set
    sockopt :rate,                     8,  :int        # set get
    sockopt :recovery_ivl,             9,  :int        # set get
    sockopt :sndbuf,                   11, :int        # set get
    sockopt :rcvbuf,                   12, :int        # set get
    sockopt :rcvmore,                  13, :int        #     get
    sockopt :fd,                       14, :int        #     get
    sockopt :events,                   15, :int        #     get
    sockopt :type,                     16, :int        #     get
    sockopt :linger,                   17, :int        # set get
    sockopt :reconnect_ivl,            18, :int        # set get
    sockopt :backlog,                  19, :int        # set get
    sockopt :reconnect_ivl_max,        21, :int        # set get
    sockopt :maxmsgsize,               22, :long_long  # set get
    sockopt :sndhwm,                   23, :int        # set get
    sockopt :rcvhwm,                   24, :int        # set get
    sockopt :multicast_hops,           25, :int        # set get
    sockopt :rcvtimeo,                 27, :int        # set get
    sockopt :sndtimeo,                 28, :int        # set get
    sockopt :ipv4only,                 31, :int        # set get
    sockopt :last_endpoint,            32, :string     #     get
    sockopt :router_mandatory,         33, :int        # set
    sockopt :tcp_keepalive,            34, :int        # set get
    sockopt :tcp_keepalive_cnt,        35, :int        # set get
    sockopt :tcp_keepalive_idle,       36, :int        # set get
    sockopt :tcp_keepalive_intvl,      37, :int        # set get
    sockopt :tcp_accept_filter,        38, :bytes      # set
    sockopt :delay_attach_on_connect,  39, :int        # set get
    sockopt :xpub_verbose,             40, :int        # set

    enum :sockopt, sockopts.values.flat_map { |sockopt| [sockopt.name, sockopt.num] }

    HAUSNUMERO = 156384712

    NATIVE_ERRORS = enum :native_errors, [:efsm, HAUSNUMERO + 51, :enocompatproto, :eterm, :emthread]

    ZMQ_MSG_T = 32

    def self.setsockopt(socket, socket_option, value)
      case sockopts[socket_option].type
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
    attach_function :zmq_ctx_destroy, [:pointer],                :int,     blocking: true
    attach_function :zmq_ctx_get,     [:pointer, :ctxopt],       :int,     blocking: true
    attach_function :zmq_ctx_new,     [],                        :pointer, blocking: true
    attach_function :zmq_ctx_set,     [:pointer, :ctxopt, :int], :int,     blocking: true
    attach_function :zmq_socket,      [:pointer, :socket_type],  :pointer, blocking: true

    # Socket API
    attach_function :zmq_bind,       [:pointer, :string],                      :int,     blocking: true
    attach_function :zmq_connect,    [:pointer, :string],                      :int,     blocking: true
    attach_function :zmq_getsockopt, [:pointer, :sockopt, :pointer, :pointer], :int,     blocking: true
    attach_function :zmq_setsockopt, [:pointer, :sockopt, :pointer, :size_t],  :int,     blocking: true
    attach_function :zmq_close,      [:pointer],                               :int,     blocking: true
    attach_function :zmq_disconnect, [:pointer, :string],                      :int,     blocking: true
    attach_function :zmq_unbind,     [:pointer, :string],                      :int,     blocking: true

    # attach_function :zmq_recv, [:pointer, :pointer, :size_t, :int], :int, blocking: true
    # attach_function :zmq_send, [:pointer, :pointer, :size_t, :int], :int, blocking: true
    attach_function :zmq_recv,       [:pointer, :pointer, :size_t, :int],              :int, blocking: true
    attach_function :zmq_send,       [:pointer, :pointer, :size_t, :int],              :int, blocking: true
    # attach_function :zmq_socket_monitor, [], :int, blocking: true

    # Message API
    attach_function :zmq_msg_close,     [:pointer],                                        :int,     blocking: true
    attach_function :zmq_msg_init,      [:pointer],                                        :int,     blocking: true
#    attach_function :zmq_msg_init_data, [:pointer, :pointer, :size_t, :pointer, :pointer], :int,     blocking: true
    attach_function :zmq_msg_init_size, [:pointer, :size_t],                               :int,     blocking: true
    attach_function :zmq_msg_data,      [:pointer],                                        :pointer, blocking: true
    attach_function :zmq_msg_recv,      [:pointer, :pointer, :int],                        :int,     blocking: true
    attach_function :zmq_msg_send,      [:pointer, :pointer, :int],                        :int,     blocking: true
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
    # attach_function :zmq_msg_move, [], :int, blocking: true
    # attach_function :zmq_msg_set, [], :int, blocking: true

    # Proxy API
    attach_function :zmq_proxy, [:pointer, :pointer, :pointer], :int, blocking: true

    # Misc API
    def self.errno
      FFI.errno
    end

    attach_function :zmq_strerror, [:int], :pointer, blocking: true
    def self.strerror
      zmq_strerror(errno).read_string
    end

    attach_function :zmq_poll, [:pointer, :int, :long], :int, blocking: true


    # attach_function :zmq_errno, [], :int, blocking: true
    # attach_function :zmq_version, [], :int, blocking: true

    # Deprecated API

    # attach_function :zmq_init, [], :int, blocking: true
    # attach_function :zmq_recvmsg, [], :int, blocking: true
    # attach_function :zmq_sendmsg, [], :int, blocking: true
    # attach_function :zmq_term, [], :int, blocking: true
  end

end
