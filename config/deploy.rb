require 'bundler/capistrano'

if(variables.include?(:environment))
  set :rails_env, "#{environment}"
else
  set :rails_env, "staging"
end

if(variables.include?(:host))
  set :application, "#{host}"
else
  set :application, 'finditproxy.vagrant.vm'
end

set :deploy_to, "/var/www/#{application}"
role :web, "#{application}"
role :app, "#{application}"
role :db, "#{application}", :primary => true

default_run_options[:pty] = true

ssh_options[:forward_agent] = false
set :user, 'capistrano'
set :use_sudo, false
set :copy_exclude, %w(.git jetty feature spec)

if fetch(:application).end_with?('vagrant.vm')
  set :scm, :none
  set :repository, '.'
  set :deploy_via, :copy
  set :copy_strategy, :export
  ssh_options[:keys] = [ENV['IDENTITY'] || './vagrant/puppet-applications/vagrant-modules/vagrant_capistrano_id_dsa']
else
  set :deploy_via, :remote_cache
  set :scm, :git
  if(variables.include?(:scm_user))
    set :scm_username, "#{scm_user}"
  else
    set :scm_username, "#{user}"
  end
  set :repository, "#{scm_url}"
  if variables.include?(:branch_name)
    set :branch, "#{branch_name}"
  else
    set :branch, 'master'
  end
  set :git_enable_submodules, 1
end

# tasks

before "deploy:migrate", "config:symlink"
after "deploy:update", "deploy:cleanup"

namespace :config do
  desc "linking configuration to current release"
  task :symlink do
    run "ln -nfs #{deploy_to}/shared/config/application.local.rb #{release_path}/config/application.local.rb"
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
  end
end

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end
