task :default => :help

desc "Show help menu"
task :help do
  system("bundle exec rake -T")
end

desc "Open a rails-like console with all the enviroment loaded"
task :console do
  puts "Loading console..."
  system("pry -r ./config/load.rb")
end

desc "Install sidekiq-pro gem in vendor/gems/"
task :install_sidekiq_pro do
  username = ENV["SIDEKIQ_PRO_USERNAME"]
  password = ENV["SIDEKIQ_PRO_PASSWORD"]
  version = ENV["SIDEKIQ_PRO_VERSION"]
  sidekiq_pro_gem_server = "https://#{username}:#{password}@gems.contribsys.com/"

  system(%Q(gem sources --add "#{sidekiq_pro_gem_server}"))
  system("gem install sidekiq-pro -v #{version}")
  system("gem unpack sidekiq-pro -v #{version} --target vendor/gems/")
  system("gem specification sidekiq-pro -v #{version} --ruby --remote > vendor/gems/sidekiq-pro-#{version}/sidekiq-pro.gemspec")
  puts <<-INSTRUCTIONS
Successfully installed sidekiq-pro in vendor/gems/. Add

  gem "sidekiq-pro", "#{version}", :path => "vendor/gems/sidekiq-pro-#{version}"

to the Gemfile and run

  bundle install

to start using it.
INSTRUCTIONS
end

desc "Move app image assets to public folder"
task :move_assets do
  puts "Moving app image assets to public folder..."
  require './config/load'
  SupportBeeApp::Build.move_assets
end
