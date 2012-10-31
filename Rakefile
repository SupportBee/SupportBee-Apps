require 'rspec/core/rake_task'

task :default => :help

desc "Run specs"
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = './spec/**/*_spec.rb'
  end
end

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

desc "Show help menu"
task :help do
  puts "Available rake tasks: "
  puts "rake console - Run a IRB console with all enviroment loaded"
  puts "rake spec - Run specs and calculate coverage"
  puts "rake build_js - Build SB.Apps javascript file"
end
