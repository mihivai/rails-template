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

  group :development, :test do
    gem 'pry-byebug'
  end

  group :development do
    gem 'letter_opener'
    gem "web-console"
  end

  group :test do
    gem "capybara"
    gem "selenium-webdriver"
    gem "webdrivers"
  end
  RUBY
end

def add_pages_home
  <<-HTML
  <%= content_for :meta_title, "Yourdomain - Your Meta" %>

  <div class="container page-min-height">
    <h1>Pages#Home</h1>
    <p>Find me in app/views/pages/home.html.erb</p>
  </div>
  HTML
end

def add_pages_legal
  <<-HTML
  <% content_for(:robots) do %>
    <meta name="robots" content='noindex, nofollow'>
  <% end %>

  <div class="container page-min-height">
    <h1>Pages#Legal</h1>
    <p>Find me in app/views/pages/legal.html.erb</p>
  </div>
  HTML
end

# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile',
  add_gems

# Ruby version
########################################
file '.ruby-version', '3.1.0'

# Generate the Gemfile.lock
run 'bundle install'

# Generators
########################################
generators = <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :test_unit, fixture: false
  end
RUBY

environment generators

environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }", env: 'development'
environment "config.action_mailer.default_url_options = { host: 'your-production-url.com' }", env: 'production'


# Set up the database
after_bundle do
  rails_command 'db:drop db:create db:migrate'
  generate(:controller, "pages", "home", "--skip-routes", "--no-test-framework")

  # Routes
  ########################################
  route 'root to: "pages#home"'


  # Git ignore
  ########################################
  run 'rm .gitignore'
  file '.gitignore', <<-TXT
/.bundle

# Ignore all logfiles and tempfiles.
/log/*
/tmp/*
!/log/.keep
!/tmp/.keep

# Ignore pidfiles, but keep the directory.
/tmp/pids/*
!/tmp/pids/
!/tmp/pids/.keep

# Ignore uploaded files in development.
/storage/*
!/storage/.keep
/tmp/storage/*
!/tmp/storage/
!/tmp/storage/.keep

/public/assets

# Ignore master key for decrypting credentials and more.
/config/master.key
.env*

/config/credentials/development.key

/config/credentials/staging.key

/config/credentials/production.key

TXT

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')
  generate('devise:views')

  # Install Pundit
  generate 'pundit:install'

  # Install Draper
  generate 'draper:install'

  # Install Simple Form
  generate 'simple_form:install'

  # Install Stimulus
  run 'bin/rails stimulus:install'

  # Pages Controller
  ########################################
    run 'rm app/controllers/pages_controller.rb'
    file 'app/controllers/pages_controller.rb', <<-RUBY
  class PagesController < ApplicationController
    skip_before_action :authenticate_user!, only: [:home, :legal]

    def home
    end

    def legal
    end
  end
  RUBY

  file 'app/views/pages/legal.html.erb',
    add_pages_legal

  run 'rm app/views/pages/home.html.erb'
  file 'app/views/pages/home.html.erb',
    add_pages_home
end

# Configure Turbo Streams for Rails 7
initializer 'turbo_streams.rb', <<-CODE
if Rails.application.config.respond_to?(:action_cable)
  Rails.application.config.action_cable.use_default_mount_path = false
  Rails.application.config.action_cable.mount_path = '/cable'
end
CODE


# Git
########################################
git :init
git add: '.'
git commit: "-m 'Initial commit of Mihivai App'"
