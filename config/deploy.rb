# config valid only for Capistrano 3.1
lock '3.9.1'

set :application, 'etmoses'
set :repo_url, 'https://github.com/quintel/etmoses.git'

# Set up rbenv
set :rbenv_type, :user
set :rbenv_ruby, '2.4.2'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}

set :bundle_binstubs, (-> { shared_path.join('sbin') })

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/email.yml config/secrets.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{
  sbin log tmp/pids tmp/cache tmp/sockets vendor/bundle
  public/system data/curves
}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  # build_missing_styles needs to be disabled for the cold (first) deploy.
  after 'deploy:compile_assets', 'paperclip:build_missing_styles'

  after 'deploy:finished', 'airbrake:deploy'
  after :publishing, :restart
end
