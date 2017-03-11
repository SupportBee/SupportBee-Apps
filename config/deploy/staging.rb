# Staging cap file

# Bonus! Colors are pretty!
def red(str)
  "\e[31m#{str}\e[0m"
end

def current_git_branch
  branch = `git symbolic-ref HEAD 2> /dev/null`.strip.gsub(/^refs\/heads\//, '')
  puts "Deploying branch #{red branch}"
  branch
end

role :app, fetch(:staging_server)
role :primary_app, fetch(:staging_server)
set :branch, current_git_branch
set :rails_env, "staging"
