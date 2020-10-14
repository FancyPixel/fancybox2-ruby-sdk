require_relative 'lib/fancybox2/version'

Gem::Specification.new do |spec|
  spec.name          = 'fancybox2'
  spec.version       = Fancybox2::VERSION
  spec.author        = 'Alessandro Verlato'
  spec.email         = 'alessandro@fancypixel.it'

  spec.summary       = 'Fancybox 2 Ruby SDK'
  spec.homepage      = 'https://github.com/Fancybox2/ruby-sdk'
  spec.license       = 'MIT'

  spec.files         = Dir['README.md', 'MIT-LICENSE', 'lib/**/*.rb']
  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'zeitwerk',   '~> 2.3.0'
  # spec.add_dependency 'paho-mqtt'
  spec.add_dependency 'concurrent-ruby',  '~> 1.1.6'
end
