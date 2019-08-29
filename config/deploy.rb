RAILS_ROOT = File.expand_path("../..", __FILE__)

require 'capistrano/ext/multistage'
# require 'rvm/capistrano'

set :application, "supportbee_app_platform"
set :deploy_to, "/home/rails/apps/#{application}"
set :scm, :git
set :user, "rails"
set :ssh_options, { :forward_agent => true }
# set :default_shell, '/bin/bash -l'
set :deploy_via, :remote_cache
set :use_sudo, false

set :default_stage, "staging"

set :rvm_type, :system
ruby_version = File.read(File.join(RAILS_ROOT, ".ruby-version")).chomp
set :rvm_ruby_string, ruby_version

after "deploy:update_code", "supportbee_app_platform:symlink_config_files",
                            "bundler:bundle_new_release",
                            "supportbee_app_platform:move_image_assets_to_public_folder"
after "deploy", "deploy:cleanup"
namespace :deploy do
  task :restart, :roles => :app do
    supportbee_app_platform.unicorn.restart
    # supportbee_app_platform.unicorn.stop_start
  end
end
after "deploy:restart", "supportbee_app_platform:eye:quit"
after "deploy:restart", "supportbee_app_platform:eye:_load"

rvm_exec = "/usr/local/rvm/bin/rvm-exec"

namespace :supportbee_app_platform do
  task :symlink_config_files do
    source_destination_mapping = Hash.new { |_, source_file| source_file }

    %w(sba_config.yml secret_config.yml omniauth.platform.yml honeybadger.yml assets.yml).each do |source_file|
      destination_file = source_destination_mapping[source_file]
      run <<-CMD
        ln -nfs #{shared_path}/system/#{source_file} #{release_path}/config/#{destination_file}
      CMD
    end
  end

  task :move_image_assets_to_public_folder, :roles => :primary_app do
    run <<-CMD
      cd #{release_path} && #{rvm_exec} #{fetch(:rvm_ruby_string)} bundle exec rake move_assets RACK_ENV=#{stage} --trace
    CMD
  end

  namespace :unicorn do
    task :restart do
      run <<-CMD
        /etc/init.d/unicorn_supportbee_app_platform restart
      CMD
    end

    task :stop do
      unicorn_pid_path = File.join(shared_path, "pids", "unicorn.#{fetch(:stage)}.pid")
      run <<-CMD
        test -f #{unicorn_pid_path} && /etc/init.d/unicorn_supportbee_app_platform stop || true
      CMD
    end

    task :start do
      run <<-CMD
        /etc/init.d/unicorn_supportbee_app_platform start
      CMD
    end

    task :stop_start do
      stop
      start
    end
  end

  namespace :eye do
    task :_load do
      fetch(:eye_config_dirs).each do |eye_config_dir|
        run <<-CMD
          #{rvm_exec} ruby-1.9.3-p484 eye load #{eye_config_dir}/`hostname`.eye
        CMD
      end
    end

    task :restart do
      run <<-CMD
        #{rvm_exec} ruby-1.9.3-p484 eye restart AppPlatform
      CMD
    end

    task :quit do
      run <<-CMD
        test -S ~/.eye/sock && (#{rvm_exec} ruby-2.2.3 eye quit -s) || true
      CMD
    end
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
    run "cd #{release_path} && #{rvm_exec} #{fetch(:rvm_ruby_string)} bundle install --without test development cucumber --deployment"
  end
end
