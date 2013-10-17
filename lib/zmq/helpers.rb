module ZMQ
  module Helpers
    def send_recv_opts(flags)
      flags.reduce(0) do |flags, flag|
        int_flag = flag.is_a?(Symbol) ? LibZMQ::SEND_RECV_OPTS[flag] : flag
        raise ArgumentError, "Unknown option: #{flag}" unless int_flag
        flags | int_flag
      end
    end
  end
end
