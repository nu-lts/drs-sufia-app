source 'https://rubygems.org'

gem "colorize", "0.6.0"
gem "sshkit", github: "cheald/sshkit", branch: "fix_multithread_conn_pooling"
gem 'rails', '3.2.12'
gem 'redis-rails'
gem 'mysql2' # Used in staging environment.
gem 'retries'
gem 'sqlite3'
gem 'blacklight'
gem 'blacklight_advanced_search', '~> 2.1.0'
gem 'hydra-head'
gem 'solrizer', :git => 'https://github.com/NEU-Libraries/solrizer.git', :ref => 'a304059e4bc85bbe22fc765d5e2a7ccf38ea1602'
gem 'kaminari', :git => 'https://github.com/harai/kaminari.git', :ref => 'route_prefix_prototype'  # required to handle pagination properly in dashboard. See https://github.com/amatsuda/kaminari/pull/322
gem 'omniauth'
gem 'omniauth-shibboleth'
gem 'hashie'
gem 'figaro'
gem 'bootstrap-sass', '~> 2.3.2.1'
gem 'bootstrap-slider-rails'
gem 'haml'
gem 'date_time_precision'
gem 'kramdown'
gem 'ace-rails-ap'
gem 'sanitize'
# See Bower Front-End Package Management http://bower.io Documentation
gem "bower-rails", "~> 0.5.0"
gem 'webshims-rails'
gem 'rmagick', '~> 2.13.2'
gem 'zipruby', '~> 0.3.6'
# gem 'hydra-derivatives', '~> 0.0.5'
gem 'hydra-derivatives', :git => 'https://github.com/NEU-Libraries/hydra-derivatives.git', :ref => 'd95f3e880a74713867f7c88b77429251cbb0b9b1'
gem 'resque-pool', '0.3.0'
gem 'mailboxer', '~> 0.11.0'
gem 'nest', '~> 1.1.1'
gem 'noid', '~> 0.6.6'
gem 'jquery-rails'
gem "devise"
gem "devise-guests", "~> 0.3"
gem "ruby-filemagic", "~> 0.4.2"
# Use whenever for scheduling timed tasks
gem "whenever", :require => false
# Add resque-web to the project
gem 'resque', :require => 'resque/server'
# This is global because it's needed for some fixture generation.
gem "factory_girl_rails", :require => false
gem 'mods_display', :git => 'https://github.com/NEU-Libraries/mods_display.git', :ref => 'af03004e2d31cac406a25364b28d2379d5b4e448'
gem 'parseconfig'
gem 'nokogiri', '~> 1.6.2.1'
gem 'nokogiri-diff'
gem 'namae'
# Monitoring
gem 'lograge'
gem 'exception_notification'
# Resque req
gem 'multi_json', '~> 1.7.9'
# Test coverage service
gem 'coveralls', require: false
gem 'diffy'

gem "ruby-prof"
gem 'picturefill'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'scut'
  gem 'compass-rails'
  gem 'uglifier', '>= 1.0.3'
end

group :development do
  # Deployment
  gem 'capistrano',  '~> 3.0.0'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'rvm1-capistrano3', require: false
  gem 'rb-readline'
end

group :development, :test do
  gem 'guard-livereload'
  gem "rspec-rails"
  gem "capybara"
  gem "launchy"
  gem "jettywrapper"
  # JS  testing framework.
  gem "jasmine"
  # jQuery Testing for Rails Apps
  # @link https://github.com/travisjeffery/jasmine-jquery-rails
  gem "jasmine-jquery-rails"
  gem "timecop"
end

group :test do
  gem "resque_spec"
end
