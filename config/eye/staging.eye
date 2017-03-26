RAILS_ENV = ENV['RAILS_ENV'] || 'staging'
WORKING_DIR = ENV['RAILS_ROOT'] || '/home/rails/apps/supportbee_app_platform/current'
PID_DIR = "#{WORKING_DIR}/tmp/pids"

Eye.config do
  logger File.join WORKING_DIR, 'log', 'eye.log'
end

Eye.application 'AppPlatform' do
  working_dir WORKING_DIR

  process 'sidekiq' do
    start_command "rvm-exec ruby-2.2.3 bundle exec sidekiq -C #{WORKING_DIR}/config/sidekiq/staging.yml -r #{WORKING_DIR}/config/load.rb"
    stop_signals [:USR1, 25.seconds, :TERM, 15.seconds] # See https://github.com/mperham/sidekiq/wiki/Signals

    env 'RAILS_ENV' => RAILS_ENV
    daemonize true
    pid_file "#{PID_DIR}/sidekiq.pid"

    stdall "#{WORKING_DIR}/log/sidekiq.log"
  end
end

