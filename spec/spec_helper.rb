ENV['RACK_ENV'] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/load")

module RackSpecHelpers
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end
end

RSpec.configure do |conf|
  conf.include RackSpecHelpers
  conf.mock_with :flexmock
end
