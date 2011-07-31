ssh_options[:username] = 'deployer'
ssh_options[:forward_agent] = true

set :application, 'nuera'
set :repository, 'ssh://git@bz-labs.com:2222/home/git/nuera.git'
set :port, 2222
set :scm, :git
set :deploy_to, "/var/www/#{application}"
set :app_server, '/etc/init.d/thin'
set :rvm_ruby_string, '1.8.7@nuera'
set :rvm_type, :user
set :config_files, %w(database.yml newrelic.yml initializers/hoptoad.rb)
set :shared_config, "#{shared_path}/config"
set :release_config, "#{release_path}/config"
set :use_sudo, false

role :web, 'nuerafitness.com'
role :app, 'nuerafitness.com'
role :db, 'nuerafitness.com'

after 'deploy', 'deploy:cleanup'
after 'deploy', 'deploy:migrate'
after 'deploy:symlink', 'deploy:symlink_configs'
after 'deploy:symlink', 'deploy:symlink_assets'

namespace :deploy do
  [:start, :stop, :restart].each do |action|
    task action do
      run "sudo #{app_server} #{action}"
    end
  end

  task :migrate do
    run "cd #{release_path}; RAILS_ENV=production bundle exec rake db:migrate --trace"
  end

  task :symlink_configs, :except => { :no_release => true } do
    config_files.each do |file|
      run "ln -nfs #{shared_config}/#{file} #{release_config}/#{file}"
    end
  end

  task :symlink_assets, :except => { :no_release => true } do
    run "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
  end
end

