$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'rvm/capistrano'

set :stages, %w(production staging testing)

