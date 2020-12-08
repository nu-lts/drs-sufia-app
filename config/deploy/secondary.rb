set :stage, :secondary

set :deploy_to, '/opt/cerberus/'
set :bundle_env_variables, {
  nokogiri_use_system_libraries: 1,
  http_proxy: "http://proxy.neu.edu:3128",
  https_proxy: "http://proxy.neu.edu:3128"
 }
set :bundle_bins, fetch(:bundle_bins, []).push('resque-pool', 'solrizerd')

# parses out the current branch you're on. See: http://www.harukizaemon.com/2008/05/deploying-branches-with-capistrano.html
current_branch = `git branch`.match(/\* (\S+)\s/m)[1]

# use the branch specified as a param, then use the current branch. If all fails use master branch
set :branch, ENV['branch'] || current_branch || "master" # you can use the 'branch' parameter on deployment to specify the branch you wish to deploy

set :user, 'drs'
set :rails_env, :secondary

server 'drs@nb9476.neu.edu', user: 'drs', roles: %w{web app db}

namespace :deploy do
  desc "Updating ClamAV"
  task :update_clamav do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "sudo freshclam", raise_on_non_zero_exit: false
    end
  end

  desc "Tell nokogiri to use system libs"
  task :nokogiri do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "cd #{release_path} && (RAILS_ENV=secondary bundle config build.nokogiri --use-system-libraries)"
    end
  end

  desc "Restarting application"
  task :start_httpd do
    on roles(:app), :in => :sequence, :wait => 5 do
      sudo "service httpd start"
    end
  end

  desc "Restarting application"
  task :stop_httpd do
    on roles(:app), :in => :sequence, :wait => 5 do
      sudo "service httpd stop"
    end
  end

  desc "Precompile"
  task :assets_kludge do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "cd #{release_path} && (RAILS_ENV=secondary rake assets:precompile)"
    end
  end

  desc "Stop the resque workers"
  task :stop_workers do
    on roles(:app), :in => :sequence, :wait => 10 do
      execute "cd #{release_path} && (RAILS_ENV=secondary kill -TERM $(cat /etc/cerberus/resque-pool.pid))", raise_on_non_zero_exit: false
      execute "kill $(ps aux | grep -i resque | awk '{print $2}')", raise_on_non_zero_exit: false
      execute "rm -f /etc/cerberus/resque-pool.pid", raise_on_non_zero_exit: false
    end
  end

  desc "Start workers"
  task :start_workers do
    on roles(:app), :in => :sequence, :wait => 10 do
      within release_path do
        execute :bundle, 'exec', 'resque-pool', '-p /etc/cerberus/resque-pool.pid', '--environment secondary', '&'
      end
    end
  end

  desc "Copy Figaro YAML"
  task :copy_yml_file do
    on roles(:app), :in => :sequence, :wait => 5 do
      execute "cp /etc/cerberus/application.yml #{release_path}/config/"
    end
  end

  desc 'Start solrizerd'
  task :start_solrizerd do
    on roles(:app), :in => :sequence, :wait => 5 do
      within release_path do
        execute :bundle, 'exec', 'solrizerd', 'restart', "--hydra_home #{release_path}", '-p 61616', '-o nb9475.neu.edu', '-d /topic/fedora.apim.update', '-s http://nb9477.neu.edu:8080/solr', '-l /var/log/solrizer.log'
      end
      # execute "cd #{release_path} && (RAILS_ENV=secondary bundle exec solrizerd restart --hydra_home #{release_path} -p 61616 -o nb9475.neu.edu -d /topic/fedora.apim.update -s http://nb9477.neu.edu:8080/solr)"
    end
  end

  desc 'Flush Redis'
  task :flush_redis do
    on roles(:app), :in => :sequence, :wait => 10 do
      execute "cd #{release_path} && (RAILS_ENV=secondary redis-cli -h nb4404.neu.edu FLUSHALL)"
    end
  end

end

# Load the rvm environment before executing the refresh data hook.
# This will be necessary for any hook that needs access to ruby.
# Note the use of the rvm-auto shell in the task definition.

# These hooks execute in the listed order after the deploy:updating task
# occurs.  This is the task that handles refreshing the app code, so this
# should only fire on actual deployments.

before 'deploy:starting', 'deploy:update_clamav'
after 'deploy:updating', 'bundler:install'
after 'deploy:updating', 'deploy:copy_yml_file'
#after 'deploy:updating', 'deploy:migrate'

after 'deploy:finished', 'deploy:start_solrizerd'
after 'deploy:finished', 'deploy:flush_redis'
after 'deploy:finished', 'deploy:stop_workers'
after 'deploy:finished', 'deploy:start_workers'
