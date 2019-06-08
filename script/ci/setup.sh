set -e

export RAILS_ENV=test
export RACK_ENV=test
export PLATFORM_ENV=test

source ~/.rvm/scripts/rvm
# Use ruby 2.2.3
# rvm use 2.2.3 --install
rvm use 2.2.10 --install

# Install bundler
gem install bundler -v 1.17.3 # Install bundler 1.17.3 as the latest version of bundler doesn't support ruby 2.2.3

# Install gems
bundle install

# Create config files
cp config/sba_config.example.yml config/sba_config.yml
cp config/omniauth.platform.example.yml config/omniauth.platform.yml
cp config/honeybadger.example.yml config/honeybadger.yml
