$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'bundesstrasse'
  s.version     = '0.0.2'
  s.platform    = 'java'
  s.authors     = ['Joel Segerlind']
  s.email       = ['joel@kogito.se']
  s.homepage    = 'https://github.com/jowl/bundesstrasse'
  s.summary     = 'A thin wrapper around ffi-rzmq, providing basic functionality'
  s.description = 'Basic ZeroMQ wrapper for JRuby'

  s.add_dependency 'ffi-rzmq'
  
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'ruby-debug'

  require 'rake'
  s.files         = FileList['lib/bundesstrasse.rb','lib/bundesstrasse/context.rb','lib/bundesstrasse/socket.rb','lib/bundesstrasse/sockets.rb']
  s.require_paths = ['lib']
end
