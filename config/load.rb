PLATFORM_ENV = ENV["RACK_ENV"] ||= "development"
PLATFORM_ROOT = File.expand_path '../../', __FILE__

require 'bundler'
Bundler.setup

Bundler.require(:default, PLATFORM_ENV.to_sym)

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/blank'

Dir["#{PLATFORM_ROOT}/lib/helpers/**/*.rb"].each { |f| require f }
Dir["#{PLATFORM_ROOT}/lib/*.rb"].each { |f| require f }
Dir["#{PLATFORM_ROOT}/apps/*/*.rb"].each { |f| require f }

APP_CONFIG = YAML.load_file("#{PLATFORM_ROOT}/config/sb_config.yml")[PLATFORM_ENV]['app_platform']

require "#{PLATFORM_ROOT}/config/environments/#{PLATFORM_ENV}"

unless PLATFORM_ENV == 'development'
  log_dir = "#{PLATFORM_ROOT}/log"
  log_filename = "#{PLATFORM_ENV}.log"
  log_url = "#{log_dir}/#{log_filename}"
  FileUtils.mkdir(log_dir) unless File.exists?(log_dir)
  log_file = File.new(log_url, 'a')
  $stdout.reopen(log_file)
  $stderr.reopen(log_file)    
  $stdout.sync=true
  $stderr.sync=true
end

require "#{PLATFORM_ROOT}/run_app"
