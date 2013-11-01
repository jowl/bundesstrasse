require 'simplecov'

SimpleCov.start do
  add_group 'ZMQ', 'lib/zmq'
  add_group 'Bundesstrasse', 'lib/bundesstrasse'
end

require 'bundesstrasse'
