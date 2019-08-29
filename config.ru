require './config/load'

puts "Preparing Assets..."
SupportBeeApp::Build.build if PLATFORM_ENV == 'development'

require "sidekiq/web"
if ["staging", "production"].include?(PLATFORM_ENV)
  SidekiqWebGoogleLogin.use
end

require 'scout_apm'
ScoutApm::Rack.install!

run Rack::URLMap.new('/' => RunApp, '/sidekiq' => Sidekiq::Web)
