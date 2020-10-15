source 'https://rubygems.org'

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gemspec

gem 'paho-mqtt', github: 'FancyPixel/paho.mqtt.ruby'

group :development do
  gem 'rake', '~> 13.0.0'
end

group :test do
  gem 'rspec', '~> 3.9.0'
  gem 'guard', '~> 2.16.2'
  gem 'guard-rspec', '~> 4.7.3'
  gem 'guard-bundler', '~> 2.2.1'
  gem 'simplecov', require: false
end
