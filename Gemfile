source 'https://rubygems.org'
gem 'savon'

group :test, :development do
  gem 'json'
  gem 'rspec'
  gem 'rspec-mocks'
  gem 'simplecov', require: false
  gem 'rake'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify'
  gem 'coveralls', require: false
  platforms :mri do
    # Temporary fix till hoe works with rbx in 1.9 mode
    gem 'hoe'
    gem 'hoe-git'
    gem 'hoe-gemspec'
    gem 'hoe-bundler'
  end
end

platforms :jruby do
  gem 'jruby-openssl'
end
