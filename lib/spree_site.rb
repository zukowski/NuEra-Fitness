require 'site_hooks.rb'

module SpreeSite
  class Engine < Rails::Engine
    def self.activate
      # Add your custom site logic here
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator.rb")) do |f|
        Rails.configuration.cache_classes ? require(f) : load(f)
      end

      [
        Calculator::Ups::Standard,
        Calculator::Freight
      ].each(&:register)

    end

    def load_tasks; end

    config.to_prepare &method(:activate).to_proc
  end
end
