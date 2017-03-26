require './config/load'

puts "Preparing Assets..."
SupportBeeApp::Build.build if PLATFORM_ENV == 'development'

# run RunApp
require "sidekiq/web"
run Rack::URLMap.new('/' => RunApp, '/sidekiq' => Sidekiq::Web)
