def add_gems
    <<-RUBY
  source 'https://rubygems.org'
  ruby '#{RUBY_VERSION}'
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

# Custom Seed
file 'lib/tasks/custom_seed.rb', <<-RUBY
  namespace :db do
    namespace :seed do
      Dir[Rails.root.join('db', 'seeds', '*.rb')].each do |filename|
        task_name = File.basename(filename, '.rb')
        desc "Seed " + task_name + ", based on the file with the same name in `db/seeds/*.rb`"
        task task_name.to_sym => :environment do
          load(filename) if File.exist?(filename)
        end
      end
    end
  end
RUBY

# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile',
  add_gems

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


# SCSS
file 'app/assets/stylesheets/components/_utilities.scss', <<-CSS
CSS


file 'app/assets/stylesheets/components/_index.scss', <<-CSS
  // Import your layouts CSS files here.
  @import "utilities";
CSS


file 'app/assets/stylesheets/config/_sizing.scss', <<-SCSS
  $sizes: 16px 20px 24px;

  @each $size in $sizes {
    .height-#{$size} {
      height: $size;
    }
    .width-#{$size} {
      width: $size;
    }
    .max-height-#{$size} {
      max-height: $size;
    }
    .max-width-#{$size} {
      max-width: $size;
    }
    .min-height-#{$size} {
      min-height: $size;
    }
    .min-width-#{$size} {
      min-width: $size;
    }
  }
SCSS

file 'app/assets/stylesheets/config/_fonts.scss', <<-SCSS
  $fonts: 16px 20px 24px;

  @each $font in $fonts {
    .font-size-#{$font} {
      font-size: $font !important;
    }
    @media(min-width:768px) {
      .font-size-md-#{$font} {
      font-size: $font !important;
      }
    }
    @media(min-width:992px) {
      .font-size-lg-#{$font} {
      font-size: $font !important;
      }
    }
    @media(min-width:1200px) {
      .font-size-xl-#{$font} {
      font-size: $font !important;
      }
    }
    @media(min-width:1400px) {
      .font-size-xxl-#{$font} {
      font-size: $font !important;
      }
    }

  }
SCSS

file 'app/assets/stylesheets/config/_colors.scss', <<-CSS
CSS

file 'app/assets/stylesheets/config/_bootstrap_variables.scss', <<-CSS
CSS

file 'app/assets/stylesheets/application.scss', <<-CSS
  @import "config/fonts";
  @import "config/colors";
  @import "config/bootstrap_variables";

  // External libraries
  @import "bootstrap/scss/bootstrap";
  @import "config/sizing";

  // Your CSS partials
  @import "components/index";
CSS

# Set up the database
after_bundle do
  run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"
  # rails_command "db:drop db:create db:migrate"
  run "bin/rails db:drop"
  run "bin/rails db:create"
  run "bin/rails db:migrate"


  append_file "app/javascript/application.js", <<~JS
    import "@hotwired/turbo-rails"
    import "controllers"
    import 'bootstrap'
  JS


  # ImportMap
  run "bundle add importmap-rails"
  # generate('importmap:install')
  run "bin/rails importmap:install"

  # file 'config/importmap.rb', <<-RUBY
  #   pin "application", preload: true
  #   pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
  #   pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.1/dist/stimulus.js"
  #   pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
  #   pin_all_from "app/javascript/controllers", under: "controllers"
  #   pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.1.3/dist/js/bootstrap.esm.js"
  #   pin "@popperjs/core", to: "https://unpkg.com/@popperjs/core@2.11.2/dist/esm/index.js"
  # RUBY


  # Devise install + user
  ########################################
  # generate('devise:install')
  run "bin/rails generate devise:install"
  # generate('devise', 'User')
  run "bin/rails generate devise User"
  # generate('devise:views')
  run "bin/rails generate devise:views"

  # Install Pundit
  # generate('pundit:install')
  run "bin/rails generate pundit:install"

  # Install Draper
  # generate('draper:install')
  run "bin/rails generate draper:install"

  # Install Simple Form
  # generate('simple_form:install', '--bootstrap')
  run "bin/rails generate simple_form:install --bootstrap"

  # Install Stimulus
  # generate('stimulus:install')
  run "bin/rails generate stimulus:install"
  # generate(:controller, "pages", "home", "--skip-routes", "--no-test-framework")
  run "bin/rails generate controller pages home --skip-routes --to-test-framework"

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


  # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit of Mihivai App'"
end


# # Generate the Gemfile.lock
# run 'bundle install'
