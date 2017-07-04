# Production cap file

role :app, fetch(:production_server)
role :primary_app, fetch(:production_server)
set :rails_env, "production"

set :eye_config_dirs, [
  "/home/rails/apps/supportbee_app_platform/current/config/eye"
]

set :branch, "master" # Always deploy master branch to production

