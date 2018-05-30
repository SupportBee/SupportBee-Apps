RAILS_ENV = ENV['RAILS_ENV'] || 'staging'
WORKING_DIR = ENV['RAILS_ROOT'] || '/home/rails/apps/supportbee_app_platform/current'
PID_DIR = "#{WORKING_DIR}/tmp/pids"

Eye.config do
  logger File.join WORKING_DIR, 'log', 'eye.log'
end

Eye.application 'AppPlatform' do
  working_dir WORKING_DIR

  sidekiq_count = Dir[WORKING_DIR + "/config/sidekiq/staging/sidekiq*.yml"].count
  (1..sidekiq_count).each do |i|
    process "sidekiq#{i}" do
      start_command "rvm-exec ruby-2.2.3 bundle exec sidekiq -C #{WORKING_DIR}/config/sidekiq/#{RAILS_ENV}/sidekiq#{i}.yml -r #{WORKING_DIR}/config/load.rb"
      stop_signals [:USR1, 25.seconds, :TERM, 15.seconds] # See https://github.com/mperham/sidekiq/wiki/Signals

      env 'RAILS_ENV' => RAILS_ENV
      daemonize true
      pid_file "#{PID_DIR}/sidekiq#{i}.pid"

      stdall "#{WORKING_DIR}/log/sidekiq#{i}.log"
    end
  end
end
