# config/unicorn.rb
# Set environment to development unless something else is specified
require 'socket'
hostname = Socket.gethostname
app_name = 'supportbee_app_platform'

env = "staging"

# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
worker_processes 8

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
#listen "/tmp/my_site.socket", :backlog => 64

# Preload our app for more speed
preload_app true

# nuke workers after 30 seconds instead of 60 seconds (the default)
#timeout 180
listen 4321

WORKING_DIR = "/home/rails/apps/#{app_name}/current"
SHARED_DIR = "/home/rails/apps/#{app_name}/shared"
working_directory WORKING_DIR
PID_PATH = "#{SHARED_DIR}/pids/unicorn.#{hostname}.pid"
pid PID_PATH
stderr_path "#{SHARED_DIR}/log/unicorn.#{hostname}.stderr.log"
stdout_path "#{SHARED_DIR}/log/unicorn.#{hostname}.stdout.log"

before_fork do |server, worker|
  # Before forking, kill the master process that belongs to the .oldbin PID.
  # This enables 0 downtime deploys.
  old_pid = "#{PID_PATH}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = "#{WORKING_DIR}/Gemfile"
end
