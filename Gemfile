source 'https://rubygems.org'

# Core gems
gem 'sinatra'
gem 'sinatra-initializers'
gem 'rake'
gem 'activesupport', :require => false
gem 'addressable'
gem 'faraday'
gem 'faraday_middleware'
gem 'hashie'
gem 'haml'
gem 'mail'
gem 'thor'
gem 'nokogiri'
gem 'htmlentities'
gem 'redis'
gem 'redis-namespace'
gem 'savon', "~> 2.1.0"
gem 'therubyracer'
gem 'coffee-script'
gem 'unicorn', '= 3.7.0'
# Monitoring
gem 'newrelic_rpm', :require => false
# Error reporting
gem 'error-reporter', :git => 'https://github.com/SupportBee/ErrorReporter.git'

# App gems
gem 'tinder'
gem 'hipchat'
gem 'evernote-thrift'
gem 'highrise'
gem 'jaconda'
gem 'ruby-trello', :require => 'trello'
gem 'flowdock'
gem 'bigcommerce', "~> 0.8.2"
gem 'rubyzoho',  "= 0.1.7"
gem 'restforce'
gem 'mab'
gem 'rest-client'

group :development, :test do
  gem 'pry'
  gem 'pry-debugger'
  gem 'awesome_print'
end

group :development do
  gem 'execjs'

  # Deploy gems
  gem 'capistrano', "= 2.15.5"
  gem 'capistrano-ext'
  gem 'rvm-capistrano'
end

group :test do
  gem 'rspec'
  gem 'vcr'
  gem 'rack-test', :require => 'rack/test'
  gem 'flexmock'
  gem 'webmock', :require => false
  gem 'mock_redis'
  gem 'timecop'
end

gem 'multimap', :git => 'https://github.com/SupportBee/multimap.git', :tag => 'v1.1.2'
