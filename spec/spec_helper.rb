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

# Prevent test unit gem from throwing errors when rspec in run
#
# Test unit gem tries to autorun tests when ruby exits. This patch
# disables the autorun behaviour.
#
# @see http://www.jonathanleighton.com/articles/2012/stop-test-unit-autorun/
class Test::Unit::Runner
  @@stop_auto_run = true
end
