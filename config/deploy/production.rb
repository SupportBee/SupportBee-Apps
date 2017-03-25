# Production cap file

role :app, fetch(:production_server)
role :primary_app, fetch(:production_server)
set :branch, "master" # Always deploy master branch to production
set :rails_env, "production"
