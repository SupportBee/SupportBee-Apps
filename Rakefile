task :default => :help

desc "Run IRB console with app environment"
task :console do
  puts "Loading development console..."
  system("irb -r ./config/load.rb")
end

desc "Build SB.Apps javascript file"
task :build_js do
  puts "Building sb.apps.js..."
  require './config/load'
  SupportBeeApp::Build.build_js
end

desc "Move app image assets to public folder"
task :move_assets do
  puts "Moving app image assets to public folder..."
  require './config/load'
  SupportBeeApp::Build.move_assets
end

desc "Show help menu"
task :help do
  puts "Available rake tasks: "
  puts "rake console - Run a IRB console with all enviroment loaded"
  puts "rake spec - Run specs and calculate coverage"
  puts "rake build_js - Build SB.Apps javascript file"
end
