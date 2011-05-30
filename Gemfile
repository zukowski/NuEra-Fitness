source 'http://rubygems.org'

gem 'rails'
gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'spree', '0.40.3'
gem 'spree_active_shipping'
gem 'spree_mail'
gem 'memcache-client'

group :development, :test do
  gem 'compass'
  gem 'rspec-rails'
  gem 'faker'
#  gem 'spork', '0.9.0.rc2'
  gem 'rcov'
  gem 'annotate-models'
  gem 'htmlentities'
end
gem 'nokogiri'

group :production do
  gem 'mysql2'
  gem 'hoptoad_notifier'
  gem 'newrelic_rpm'
end

group :noload do
  gem 'factory_girl_rails'
end
gem "product_feeds", :path => "product_feeds", :require => "product_feeds"
