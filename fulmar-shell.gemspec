# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fulmar/shell'

Gem::Specification.new do |spec|
  spec.name          = 'fulmar-shell'
  spec.version       = Fulmar::Shell::VERSION
  spec.authors       = ['Gerrit Visscher']
  spec.email         = ['g.visscher@core4.de']

  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = 'TODO: Set to \'http://mygemserver.com\' to prevent pushes to rubygems.org, or delete to allow pushes to any server.'
  # end

  spec.summary       = 'Small service to run shell commands on a local or remote shell'
  spec.description   = 'This service takes a directory and a hostname (which might be \'localhost\'). It then runs all commands given in the given directory on that machine.'
  spec.homepage      = 'https://github.com/CORE4/fulmar-shell'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(/^(test|spec|features)\//) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
end
