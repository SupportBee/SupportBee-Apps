ENV['RACK_ENV'] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/load")
require 'vcr'
require 'webmock/rspec'

module RackSpecHelpers
  include Rack::Test::Methods

  def app
    RunApp
  end
end

RSpec.configure do |config|
  config.include RackSpecHelpers
  config.mock_with :flexmock

  # Use should syntax, just like the core app
  config.expect_with :rspec do |c|
    c.syntax = :should
  end
end

VCR.configure do |c|
  #the directory where your cassettes will be saved
  c.cassette_library_dir = 'spec/vcr'
  # your HTTP request service. You can also use fakeweb, webmock, and more
  c.hook_into :webmock
end

class HashWithIndifferentAccess < Hash
  def initialize(hash)
    @hash = hash
  end

  def [](key)
    @hash[key.to_s] || @hash[key.to_sym]
  end
end

class Faraday::Response
  def body
    ret = finished? ? env[:body] : nil
    HashWithIndifferentAccess.new(JSON.parse(ret))
  rescue
    ret
  end
end

class ErrorReporter
  def self.report(e, context)
    puts ">>> [ERROR] Request: #{e.request}" if e.respond_to?(:request)
    puts ">>> [ERROR] Context: #{context}"
    puts ">>> [ERROR] Backtrace: #{e.backtrace.reject {|line| line =~ /\/gems\//} }"
  end
end
