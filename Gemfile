source 'http://rubygems.org'

gem 'rails', '3.0.4'
gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'spree', '0.40.3'
gem 'spree_active_shipping', '1.0.0'
gem 'spree_mail', '0.40.0.4'
gem 'memcache-client', '1.8.5'
gem 'nokogiri', '1.4.4'
gem 'RedCloth', '4.2.7'
gem 'htmlentities', '4.3.0'

group :development, :test do
  gem 'rspec-rails'
  gem 'faker'
  gem 'spork', '0.9.0.rc8'
  gem 'annotate-models'
  gem 'capistrano'
  gem 'capistrano-ext'
end

group :test do
  gem 'autotest'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'cucumber-rails'
  gem 'launchy'
end


group :production do
  gem 'mysql2', '0.2.7'
  gem 'hoptoad_notifier'
  gem 'newrelic_rpm'
end

gem "product_feeds", :path => "product_feeds", :require => "product_feeds"
