$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'bzmq'
  s.version     = '0.0.1'
  s.platform    = 'java'
  s.authors     = ['Joel Segerlind']
  s.email       = ['joel@kogito.se']
  s.homepage    = ''
  s.summary     = 'A thin wrapper around ffi-rzmq, providing basic functionality'
  s.description = 'Basic ZeroMQ wrapper for JRuby'

  s.rubyforge_project = 'bzmq'

  s.add_dependency 'ffi-rzmq'
  
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'ruby-debug'

  require 'rake'
  s.files         = FileList['lib/bzmq.rb','lib/bzmq/context.rb','lib/bzmq/socket.rb','lib/bzmq/sockets.rb']
  s.require_paths = ['lib']
end
