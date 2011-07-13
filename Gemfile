source 'http://rubygems.org'

gem 'rails'
gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'spree', '0.40.3'
gem 'spree_active_shipping'
gem 'spree_mail'
gem 'memcache-client'
gem 'nokogiri'

group :development, :test do
  gem 'rspec-rails'
  gem 'faker'
  gem 'spork', '0.9.0.rc8'
  gem 'annotate-models'
  gem 'htmlentities'
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
  gem 'mysql2'
  gem 'hoptoad_notifier'
  gem 'newrelic_rpm'
end

gem "product_feeds", :path => "product_feeds", :require => "product_feeds"
