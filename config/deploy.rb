require 'capistrano/ext/multistage'
require 'rvm/capistrano'

set :application, "supportbee_app_platform"
set :deploy_to, "/home/rails/apps/#{application}"
set :scm, :git
set :user, "rails"
set :ssh_options, { :forward_agent => true }
set :deploy_via, :remote_cache
set :use_sudo, false

set :default_stage, "staging"

set :rvm_type, :system
set :rvm_ruby_string, '1.9.3-p484'

after "deploy:update_code", "supportbee_app_platform:symlink_config_files",
                            "bundler:bundle_new_release",
                            "supportbee_app_platform:move_image_assets_to_public_folder"

after "deploy", "deploy:cleanup"

namespace :deploy do
  task :restart, :roles => :app do
    run <<-CMD
      /etc/init.d/unicorn_supportbee_app_platform restart
    CMD
  end
end

namespace :supportbee_app_platform do
  task :symlink_config_files do
    source_destination_mapping = Hash.new { |_, source_file| source_file }
    source_destination_mapping['newrelic.platform.yml'] = 'newrelic.yml'

    %w(sba_config.yml secret_config.yml omniauth.platform.yml newrelic.platform.yml honeybadger.yml assets.yml).each do |source_file|
      destination_file = source_destination_mapping[source_file]
      run <<-CMD
        ln -nfs #{shared_path}/system/#{source_file} #{release_path}/config/#{destination_file}
      CMD
    end
  end

  task :move_image_assets_to_public_folder, :roles => :primary_app do
    run <<-CMD
      cd #{release_path} && rake move_assets RACK_ENV=#{stage} --trace
    CMD
  end
end

namespace :bundler do
  task :create_symlink do
    shared_dir = File.join(shared_path, 'bundle')
    release_dir = File.join(current_release, 'vendor', 'bundle')
    run "mkdir -p #{release_dir} && mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}"
  end

  task :bundle_new_release do
    bundler.create_symlink
    run "cd #{release_path} && bundle install --without test development cucumber --deployment"
  end

  task :lock do
    run "cd #{current_release} && bundle lock;"
  end

  task :unlock do
    run "cd #{current_release} && bundle unlock;"
  end
end
