ssh_options[:username] = 'deployer'
ssh_options[:forward_agent] = true

set :application, 'nuera'
set :repository, 'ssh://git@bz-labs.com:2222/home/git/nuera.git'
set :port, 2222
set :scm, :git
set :deploy_to, "/var/www/#{application}"
set :app_server, '/etc/init.d/thin'

role :web, 'nuerafitness.com'
role :app, 'nuerafitness.com'
role :db, 'nuerafitness.com'

after 'deploy', 'deploy:cleanup'
after 'deploy', 'deploy:symlink_db'
after 'deploy', 'deploy:migrate'

namespace :deploy do
  [:start, :stop, :restart].each do |action|
    task action do
      run "#{try_sudo} #{app_server} #{action}"
    end
  end

  task :migrate do
    run 'cd #{release_path}; RAILS_ENV=production bundle exec rake db:migrate'
  end

  task :symlink_db, :except => { :no_release => true } do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
end

