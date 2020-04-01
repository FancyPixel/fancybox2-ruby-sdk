require_relative 'lib/fancybox2/version'

Gem::Specification.new do |spec|
  spec.name          = 'fancybox2'
  spec.version       = Fancybox2::VERSION
  spec.author        = 'Alessandro Verlato'
  spec.email         = 'alessandro@fancypixel.it'

  spec.summary       = 'Consume HTTP APIs with style'
  spec.homepage      = 'https://github.com/madAle/api_recipes'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'zeitwerk',   '~> 2.3.0'
  spec.add_dependency 'paho-mqtt',  '~> 1.0.12'
end
