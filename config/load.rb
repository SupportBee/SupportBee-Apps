PLATFORM_ENV = ENV["RACK_ENV"] ||= "development"
PLATFORM_ROOT = File.expand_path '../../', __FILE__

require 'bundler'
Bundler.setup

Bundler.require(:default, PLATFORM_ENV.to_sym)

# Setup newrelic monitoring
if ['staging', 'production'].include?(PLATFORM_ENV)
  require 'newrelic_rpm'
end

require "#{PLATFORM_ROOT}/config/environments/#{PLATFORM_ENV}"

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/blank'

Dir["#{PLATFORM_ROOT}/lib/helpers/**/*.rb"].each { |f| require f }
Dir["#{PLATFORM_ROOT}/lib/*.rb"].each { |f| require f }
Dir["#{PLATFORM_ROOT}/apps/*/*.rb"].each { |f| require f }
Dir["#{PLATFORM_ROOT}/workers/*.rb"].each { |f| require f }

app_config = YAML.load_file("#{PLATFORM_ROOT}/config/sba_config.yml")[PLATFORM_ENV]['app_platform']
SECRET_CONFIG = YAML.load_file("#{PLATFORM_ROOT}/config/secret_config.yml")[PLATFORM_ENV]
OMNIAUTH_CONFIG = YAML.load_file("#{PLATFORM_ROOT}/config/omniauth.platform.yml")[PLATFORM_ENV]

# Override the config of core app to local server if super user
if ENV['SU']
  app_config['core_app_base_domain'] = 'lvh.me'
  app_config['core_app_port'] = 3000
  app_config['core_app_protocol'] =  'http'
end

APP_CONFIG = app_config

log_dir = "#{PLATFORM_ROOT}/log"
log_filename = "#{PLATFORM_ENV}.log"
log_url = "#{log_dir}/#{log_filename}"
FileUtils.mkdir(log_dir) unless File.exists?(log_dir)
LOGGER = Logger.new(log_url)

REDIS_CONFIG = APP_CONFIG['redis']
redis = nil
if PLATFORM_ENV == 'test'
  require 'mock_redis'
  redis = MockRedis.new(db: REDIS_CONFIG['db'])
else
  redis = Redis.new(host: REDIS_CONFIG['host'], db: REDIS_CONFIG['db'])
  redis = Redis::Namespace.new(:ap, redis: redis)
end
REDIS = redis

if PLATFORM_ENV == 'development'
  require 'pry'
end

require 'error-reporter'
require "#{PLATFORM_ROOT}/run_app"

#
# Sidekiq
#

SIDEKIQ_REDIS_CONFIG = APP_CONFIG['sidekiq_redis']
default_redis_port = 6379
port = SIDEKIQ_REDIS_CONFIG['port'] || default_redis_port
redis_url = URI::Generic.build(scheme: "redis", host: REDIS_CONFIG['host'], port: port, path: "/#{REDIS_CONFIG['db']}").to_s # redis://127.0.0.1:6379/2
Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end
Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
