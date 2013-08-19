$: << File.expand_path('../lib', __FILE__)

require 'bundesstrasse/version'

Gem::Specification.new do |s|
  s.name        = 'bundesstrasse'
  s.version     = Bundesstrasse::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Joel Segerlind']
  s.email       = ['joel@kogito.se']
  s.homepage    = 'https://github.com/jowl/bundesstrasse'
  s.summary     = 'A 0MQ wrapper for Ruby using FFI'
  s.description = 'A 0MQ wrapper for Ruby using FFI'

  s.add_dependency 'ffi'

  s.add_development_dependency 'rspec'

  s.files         = Dir['lib/**/*.rb']
  s.require_paths = %w[lib]
end
