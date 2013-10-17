require 'ffi'

module ZMQ
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
    sockopt :affinity,                 4,  :ulong_long  # set get
    sockopt :identity,                 5,  :bytes       # set get
    sockopt :subscribe,                6,  :bytes       # set
    sockopt :unsubscribe,              7,  :bytes       # set
    sockopt :rate,                     8,  :int         # set get
    sockopt :recovery_ivl,             9,  :time_period # set get
    sockopt :sndbuf,                   11, :int         # set get
    sockopt :rcvbuf,                   12, :int         # set get
    sockopt :rcvmore,                  13, :boolean     #     get
    sockopt :fd,                       14, :int         #     get
    sockopt :events,                   15, :int         #     get
    sockopt :type,                     16, :int         #     get
    sockopt :linger,                   17, :time_period # set get
    sockopt :reconnect_ivl,            18, :time_period # set get
    sockopt :backlog,                  19, :int         # set get
    sockopt :reconnect_ivl_max,        21, :time_period # set get
    sockopt :maxmsgsize,               22, :long_long   # set get
    sockopt :sndhwm,                   23, :int         # set get
    sockopt :rcvhwm,                   24, :int         # set get
    sockopt :multicast_hops,           25, :int         # set get
    sockopt :rcvtimeo,                 27, :time_period # set get
    sockopt :sndtimeo,                 28, :time_period # set get
    sockopt :ipv4only,                 31, :boolean     # set get
    sockopt :last_endpoint,            32, :string      #     get
    sockopt :router_mandatory,         33, :boolean     # set
    sockopt :tcp_keepalive,            34, :int         # set get
    sockopt :tcp_keepalive_cnt,        35, :int         # set get
    sockopt :tcp_keepalive_idle,       36, :int         # set get
    sockopt :tcp_keepalive_intvl,      37, :int         # set get
    sockopt :tcp_accept_filter,        38, :bytes       # set
    sockopt :delay_attach_on_connect,  39, :boolean     # set get
    sockopt :xpub_verbose,             40, :int         # set

    enum :sockopt, sockopts.values.flat_map { |sockopt| [sockopt.name, sockopt.num] }
    enum :ctxopt, [:io_threads, 1, :max_sockets]
    SOCKET_TYPES = enum :socktype, [:pair, :pub, :sub, :req, :rep, :dealer, :router, :pull, :push, :xpub, :xsub]
    SEND_RECV_OPTS = enum :dontwait, 1, :sndmore
    EVENT_FLAGS = enum :pollin, 1, :pollout, :pollerr, 4
    HAUSNUMERO = 156384712
    NATIVE_ERRORS = enum :efsm, HAUSNUMERO + 51, :enocompatproto, :eterm, :emthread
    ZMQ_MSG_T = 32

    # Context API
    attach_function :zmq_ctx_destroy,      [:pointer],                               :int,     blocking: true
    attach_function :zmq_ctx_get,          [:pointer, :ctxopt],                      :int,     blocking: true
    attach_function :zmq_ctx_new,          [],                                       :pointer, blocking: true
    attach_function :zmq_ctx_set,          [:pointer, :ctxopt, :int],                :int,     blocking: true
    attach_function :zmq_socket,           [:pointer, :socktype],                    :pointer, blocking: true

    # Socket API
    attach_function :zmq_bind,             [:pointer, :string],                      :int,     blocking: true
    attach_function :zmq_connect,          [:pointer, :string],                      :int,     blocking: true
    attach_function :zmq_getsockopt,       [:pointer, :sockopt, :pointer, :pointer], :int,     blocking: true
    attach_function :zmq_setsockopt,       [:pointer, :sockopt, :pointer, :size_t],  :int,     blocking: true
    attach_function :zmq_close,            [:pointer],                               :int,     blocking: true
    attach_function :zmq_disconnect,       [:pointer, :string],                      :int,     blocking: true
    attach_function :zmq_unbind,           [:pointer, :string],                      :int,     blocking: true
    attach_function :zmq_recv,             [:pointer, :pointer, :size_t, :int],      :int,     blocking: true
    attach_function :zmq_send,             [:pointer, :pointer, :size_t, :int],      :int,     blocking: true
    # attach_function :zmq_socket_monitor, [:pointer, :string, :int],                :int,     blocking: true

    # Message API
    attach_function :zmq_msg_close,        [:pointer],                               :int,     blocking: true
    attach_function :zmq_msg_init,         [:pointer],                               :int,     blocking: true
    attach_function :zmq_msg_init_size,    [:pointer, :size_t],                      :int,     blocking: true
    attach_function :zmq_msg_data,         [:pointer],                               :pointer, blocking: true
    attach_function :zmq_msg_recv,         [:pointer, :pointer, :int],               :int,     blocking: true
    attach_function :zmq_msg_send,         [:pointer, :pointer, :int],               :int,     blocking: true
    attach_function :zmq_msg_size,         [:pointer],                               :int,     blocking: true
    attach_function :zmq_msg_more,         [:pointer],                               :int,     blocking: true
    # attach_function :zmq_msg_init_data,  [],                                       :int,     blocking: true
    # attach_function :zmq_msg_copy,       [],                                       :int,     blocking: true
    # attach_function :zmq_msg_get,        [],                                       :int,     blocking: true
    # attach_function :zmq_msg_move,       [],                                       :int,     blocking: true
    # attach_function :zmq_msg_set,        [],                                       :int,     blocking: true

    # Proxy API
    attach_function :zmq_proxy,            [:pointer, :pointer, :pointer],           :int,     blocking: true

    # Poll API
    attach_function :zmq_poll,             [:pointer, :int, :long],                  :int,     blocking: true

    # Misc API
    attach_function :zmq_strerror,         [:int],                                   :pointer, blocking: true
    # attach_function :zmq_errno,          [],                                       :int,     blocking: true
    # attach_function :zmq_version,        [],                                       :int,     blocking: true

    # Deprecated API
    # attach_function :zmq_init,           [], :int, blocking: true
    # attach_function :zmq_recvmsg,        [], :int, blocking: true
    # attach_function :zmq_sendmsg,        [], :int, blocking: true
    # attach_function :zmq_term,           [], :int, blocking: true
  end
end
