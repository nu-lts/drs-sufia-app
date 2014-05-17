# Automate deployment to our local dev machine.
# This somewhat deceptively requires the use of an environment called 'staging'
# Which is really just develop with the caveat that jetty runs on port 3000.

# Sorry.

set :stage, :development
set :whenever_environment, 'staging'

set :deploy_to, '/home/drs/apps/develop/'
#set :branch, 'develop'

# parses out the current branch you're on. See: http://www.harukizaemon.com/2008/05/deploying-branches-with-capistrano.html
current_branch = `git branch`.match(/\* (\S+)\s/m)[1]

# use the branch specified as a param, then use the current branch. If all fails use master branch
set :branch, ENV['branch'] || current_branch || "develop" # you can use the 'branch' parameter on deployment to specify the branch you wish to deploy

set :user, 'drs'
set :rails_env, :staging

server 'drs@repositorydev.neu.edu', user: 'drs', roles: %w{web app db}

namespace :deploy do
  desc "Restarting application"
  task :restart do
    on roles(:app), :in => :sequence, :wait => 5 do
      sudo "service httpd restart"
    end
  end

  desc "Precompile"
  task :assets_kludge do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "cd #{release_path} && (RAILS_ENV=staging /tmp/drs/rvm-auto.sh . rake assets:precompile)"
    end
  end

  desc "Restarting the resque workers"
  task :restart_workers do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "cd #{release_path} && (RAILS_ENV=staging /tmp/drs/rvm-auto.sh . kill -TERM $(cat /home/drs/config/resque-pool.pid))"
      execute "cd #{release_path} && (RAILS_ENV=staging /tmp/drs/rvm-auto.sh . resque-pool --daemon -p /home/drs/config/resque-pool.pid)"
    end
  end

  desc "Resetting data"
  task :reset_data do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "cd #{release_path} && (RAILS_ENV=staging /tmp/drs/rvm-auto.sh . rake reset_data)"
    end
  end

  desc "Copy Figaro YAML"
  task :copy_yml_file do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "cp /home/drs/config/application.yml #{release_path}/config/"
    end
  end

  desc "Setting whenever environment and updating the crontable"
  task :whenever do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "cd #{release_path} && (RAILS_ENV=staging /tmp/drs/rvm-auto.sh . bundle exec whenever --set environment=staging)"
      execute "cd #{release_path} && (RAILS_ENV=staging /tmp/drs/rvm-auto.sh . bundle exec whenever --update-crontab)"
    end
  end

  desc "Copy rvmrc"
  task :copy_rvmrc_file do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "cp /home/drs/.drsrvmrc #{release_path}/.rvmrc"
    end
  end

  desc 'Trust rvmrc file'
  task :trust_rvmrc do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "/home/drs/.rvm/bin/rvm rvmrc trust #{release_path}"
    end
  end

  desc 'Start solrizerd'
  task :start_solrizerd do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "cd #{release_path} && (RAILS_ENV=staging /tmp/drs/rvm-auto.sh . bundle exec solrizerd restart --hydra_home #{release_path} -p 61616 -o nb4676.neu.edu -d /topic/fedora.apim.update)"
    end
  end

end

# Load the rvm environment before executing the refresh data hook.
# This will be necessary for any hook that needs access to ruby.
# Note the use of the rvm-auto shell in the task definition.
before 'deploy:reset_data', 'rvm1:hook'

# These hooks execute in the listed order after the deploy:updating task
# occurs.  This is the task that handles refreshing the app code, so this
# should only fire on actual deployments.
after 'deploy:updating', 'deploy:copy_rvmrc_file'
after 'deploy:updating', 'deploy:trust_rvmrc'
after 'deploy:updating', 'bundler:install'
after 'deploy:updating', 'deploy:copy_yml_file'
after 'deploy:updating', 'deploy:restart_workers'
after 'deploy:updating', 'deploy:migrate'
after 'deploy:updating', 'deploy:whenever'
after 'deploy:updating', 'deploy:assets_kludge'
#after 'deploy:finished', 'deploy:reset_data'
after 'deploy:finished', 'deploy:start_solrizerd'
after 'deploy:updating', 'deploy:restart'
