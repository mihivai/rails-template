def add_gems
    <<-RUBY
  source 'https://rubygems.org'
  ruby '3.1.0'
  gem 'rails', "~> 7.0.4"
  gem 'pg', "~> 1.1"
  gem "puma", "~> 5.0"
  gem 'bootstrap', '~> 5.1.3'
  gem 'devise'
  gem 'pundit'
  gem 'draper'
  gem 'simple_form'
  gem 'stimulus-rails'
  gem "importmap-rails"
  gem 'turbo-rails'
  gem "jbuilder"
  gem "sassc-rails"
  gem "bootsnap", require: false
end


# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile',
  add_gems

# Ruby version
########################################
file '.ruby-version', 3.1.0

# Generate the Gemfile.lock
run 'bundle install'

# Set up the database
after_bundle do
  rails_command 'db:drop db:create db:migrate'
end

# Generate a new Rails application
rails_command "new . --database=postgresql --skip-test --skip-system-test"

# Configure Turbo Streams for Rails 7
initializer 'turbo_streams.rb', <<-CODE
if Rails.application.config.respond_to?(:action_cable)
  Rails.application.config.action_cable.use_default_mount_path = false
  Rails.application.config.action_cable.mount_path = '/cable'
end
CODE

# Install and configure Devise
generate 'devise:install'
environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }", env: 'development'
environment "config.action_mailer.default_url_options = { host: 'your-production-url.com' }", env: 'production'

# Generate a Devise user model
generate 'devise User'

# Install Pundit
generate 'pundit:install'

# Install Draper
generate 'draper:install'

# Install Simple Form
generate 'simple_form:install'

# Install Stimulus
run 'bin/rails stimulus:install'

# Add optional features based on user input
# Active Admin
if yes?('Do you want to add Active Admin? (y/n)')
  gem 'activeadmin'
  gem 'devise-i18n'

  after_bundle do
    generate 'active_admin:install'
    generate 'devise:i18n:install'
  end
end


# Postmark
if yes?('Do you want to add Postmark? (y/n)')
  gem 'postmark-rails'

  after_bundle do
    environment "config.action_mailer.delivery_method = :postmark", env: 'production'
  end
end


 # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit of Mihivai App'"
