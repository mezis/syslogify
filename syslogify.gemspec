# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'syslogify/version'

Gem::Specification.new do |spec|
  spec.name          = "syslogify"
  spec.version       = Syslogify::VERSION
  spec.authors       = ["Julien Letessier"]
  spec.email         = ["julien.letessier@gmail.com"]
  spec.summary       = %q{Sends stdout and stderr to syslog.}
  spec.description   = %q{Sends stdout and stderr to syslog..}
  spec.homepage      = "https://github.com/mezis/syslogify"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
