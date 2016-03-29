# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen/driver/marathon_version'

Gem::Specification.new do |spec|
  spec.name          = 'kitchen-marathon'
  spec.version       = Kitchen::Driver::Version::STRING.dup
  spec.authors       = ['Anthony Spring']
  spec.email         = ['aspring@yieldbot.com']
  spec.description   = %q{A Test Kitchen Driver for Marathon}
  spec.summary       = spec.description
  spec.homepage      = 'http://github.com/yieldbot/kitchen-marathon'
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'test-kitchen',       '>= 1.0.0'
  spec.add_dependency 'marathon-api',       '~> 1.3.2'
  spec.add_dependency 'retryable',          '~> 2.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
