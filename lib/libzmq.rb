require 'ffi'

module LibZMQ
  extend FFI::Library

  ffi_lib 'libzmq'

  # Constants
  SOCKET_TYPES = enum :socket_type,      [:pair, :pub, :sub, :req, :rep, :dealer, :router, :pull, :push, :xpub, :xsub]
  enum :context_option,   [:io_threads, 1, :max_sockets]

  # Context API
  attach_function :zmq_ctx_destroy, [:pointer],                        :int,     blocking: true
  attach_function :zmq_ctx_new,     [],                                :pointer, blocking: true
  attach_function :zmq_ctx_set,     [:pointer, :context_option, :int], :int,     blocking: true

  # Socket API
  attach_function :zmq_socket,     [:pointer, :socket_type],                       :pointer, blocking: true
end
