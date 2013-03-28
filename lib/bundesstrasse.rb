require 'ffi-rzmq'

module Bundesstrasse
  Poller = ZMQ::Poller
end

require 'bundesstrasse/errors'
require 'bundesstrasse/context'
require 'bundesstrasse/socket'
require 'bundesstrasse/sockets'
require 'bundesstrasse/device'
require 'bundesstrasse/devices'
