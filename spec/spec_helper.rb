ENV['RACK_ENV'] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/load")

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
