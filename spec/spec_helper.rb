ENV['RACK_ENV'] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/load")

module RackSpecHelpers
  include Rack::Test::Methods

  def app
    RunApp
  end
end

RSpec.configure do |config|
  config.include RackSpecHelpers
  config.mock_with :flexmock
end
