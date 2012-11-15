require './config/load'

puts "Preparing Assets..."
SupportBeeApp::Build.build if PLATFORM_ENV == 'development'

run RunApp
