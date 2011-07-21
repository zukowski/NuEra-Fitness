require 'spree_site'

AppConfiguration.find_or_create_by_name("Default configuration")

Spree::Config.set(:logo => '/images/nuera-logo.png')
Spree::Config.set(:products_per_page => 12)
Spree::Config.set(:allow_ssl_in_production => true)
