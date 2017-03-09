source 'https://rubygems.org'

# Core Gems
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
# unicorn 4.1.0 fixes a bug that broke unicorn restarts
# @see http://mongrel-unicorn.rubyforge.narkive.com/QM9xHegx/ruby-2-0-bad-file-descriptor-errno-ebadf
gem 'unicorn', '>= 4.1.1'
gem 'newrelic_rpm', :require => false # Monitoring

# App Gems
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

group :development, :test do
  gem 'pry'
  gem 'awesome_print'
end

group :development do
  gem 'execjs'
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

# Mail Gems
gem 'rest-client'

# ErrorReporter
gem 'error-reporter', :git => 'https://github.com/SupportBee/ErrorReporter.git'
