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

app_config = YAML.load_file("#{PLATFORM_ROOT}/config/sba_config.yml")[PLATFORM_ENV]['app_platform']
SECRET_CONFIG = YAML.load_file("#{PLATFORM_ROOT}/config/secret_config.yml")[PLATFORM_ENV]['app_platform']

# Override the config of core app to local server if super user
if ENV['SU']
  app_config['core_app_base_domain'] = 'lvh.me'
  app_config['core_app_port'] = 3000
  app_config['core_app_protocol'] =  'http'
end

APP_CONFIG = app_config

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
