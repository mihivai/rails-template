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
gem 'rack-attack'
gem "recaptcha"
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

def generate_application_controller_with_admin
  run "rm app/controllers/application_controller.rb"
  file "app/controllers/application_controller.rb", <<~RUBY
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  after_action :verify_authorized, unless: :skip_pundit?

  def active_admin_controller?
    is_a?(ActiveAdmin::BaseController)
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/ || active_admin_controller?
  end

  def user_not_authorized
    flash[:alert] = "Vous n'êtes pas autorisé à réaliser cette action."
    redirect_to(root_path)
  end
end
  RUBY
end

def generate_application_controller_without_admin
  run "rm app/controllers/application_controller.rb"
  file "app/controllers/application_controller.rb", <<~RUBY
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  after_action :verify_authorized, except: %i[index], unless: :skip_pundit?

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end
end
  RUBY
end

def install_active_admin
  run "bundle add activeadmin"
  run "bin/rails generate active_admin:install"
  run "bin/rails db:migrate"

  run 'rm config/initializers/active_admin.rb'
  run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/config/active_admin.rb > config/initializers/active_admin.rb'
  run "bin/rails generate migration AddAdminToUsers admin:boolean"
  run "bin/rails db:migrate"

  run 'rm db/seeds.rb'
  run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/seeds.rb > db/seeds.rb'
  run "bin/rails db:seed"


  generate_application_controller_with_admin
end

def install_postmark
  run "bundle add postmark-rails"
  environment "config.action_mailer.delivery_method     = :postmark", env: 'production'
  environment "config.action_mailer.postmark_settings   = { api_token: ENV['POSTMARK_API_TOKEN'] }", env: 'production'
  environment "config.action_mailer.default_url_options = { host: ENV['DOMAIN'] }", env: 'production'

  file 'config/initializers/email_interceptor.rb', <<-RUBY
# if Rails.env.production? || Rails.env.staging?
if Rails.env.staging?
  require "email_interceptor"
  ActionMailer::Base.register_interceptor(EmailInterceptor)
end
RUBY

file 'lib/email_interceptor.rb', <<-RUBY
class EmailInterceptor
  def self.delivering_email(message)
    message.subject = "[PREPROD]" + message.to.to_s + " " + message.subject
    message.to = [ ENV['DEFAULT_EMAIL_INTERCEPTOR'] ]
  end
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

def add_layout
<<-HTML
<!DOCTYPE html>
<html>
  <head>
    <%= render "layouts/google_analytics" %>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <title><%= meta_title %></title>
    <meta name="description" content="<%= meta_description %>">
    <!-- Facebook Open Graph data -->
    <meta property="og:title" content="<%= meta_title %>" />
    <meta property="og:type" content="website" />
    <meta property="og:url" content="<%= request.original_url %>" />
    <meta property="og:image" content="<%= meta_image %>" />
    <meta property="og:description" content="<%= meta_description %>" />
    <meta property="og:site_name" content="<%= meta_title %>" />

    <%= yield(:robots) %>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
    <%#= favicon_link_tag asset_path('favicon.ico') %> <!-- Uncomment for favicon -->
  </head>
  <body>
    <%= render 'shared/navbar' %>
    <div id='flash'>
      <%= render 'shared/flashes' %>
    </div>
    <div class='container'>
      <%= yield %>
    </div>
    <%= render 'shared/footer' %>
  </body>
</html>
HTML
end

def add_flash
  run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/views/shared/flashes.html.erb > app/views/shared/_flashes.html.erb'
end

def add_google_analytics
<<-HTML
<% if Rails.env == "production"  %>
  <!-- Global site tag (gtag.js) - Google Analytics -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=<%= ENV['GOOGLE_ANALYTICS_KEY'] %>"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', "<%= ENV['GOOGLE_ANALYTICS_KEY'] %>");
  </script>
<% end %>
HTML
end

def update_error_page(var)
<<-HTML
<!DOCTYPE html>
<html>
<head>
  <title> Yourdomain - Erreur</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta charset="UTF-8">
  <style>
    body {
        background-color: white;
        color: #2E2F30;
        text-align: center;
        font-family: arial, sans-serif;
        margin: 20px;
      }

      .banner-logo img {
        max-width: 90%;
      }

      .container {
        margin: 40px auto;
      }
      h1 {
        font-size: 32px;
        margin: 0px;
      }
      p {
        font-size: 20px;
      }
      .link_mail_to {
        text-decoration: none;
        color: #2e2f30ad;
      }
      .link_mail_to:hover {
        text-decoration: none;
        color: #2E2F30;
      }
      .button-green {
        border-radius: 2px;
        margin: 20px 0px;
        text-decoration: none;
        padding: 10px 41px;
        color: white;
        background-color: #888485;
        font-weight: lighter;
      }
     .button-green:hover {
        text-decoration: none;
        background-color: #a7a4a5;
      }
    </style>
  </head>

  <body class="rails-default-error-page">
    <!-- This file lives in public/500.html -->
      <div class="banner-logo">
        <img src="logo.png" alt="logo">
      </div>
      <div class="container">
        <h1>
          Page d'erreur
        </h1>
        <p>
          Une erreur est revenue. <br> Veuillez nous excuser pour la gêne occasionée.
        </p>
         <p>
          N'hésitez pas à retourner sur la page précédente et à réessayer.
        </p>
        <p>
          <a class="link_mail_to" href="mailto:contact@mihivai.com">Reporter le probléme</a>
        </p>
      </div>
      <div class="container">
        <a class="button-green" href="/">Retour sur le site</a>
      </div>

  </body>
</html>
HTML
end

def add_navbar
<<-HTML
<div class="navbar-mihivai">
  <!-- Logo -->
  <a href="/" class="navbar-mihivai-brand">
    <%= image_tag "logo.png" %>
  </a>

  <div class="d-none d-md-block">
    <div class="d-flex align-items-center justify-content-between">
      <%= link_to "Notre Activité", "#", class: "navbar-mihivai-item navbar-mihivai-link" %>
      <%= link_to "Nos Services", "/", class: "navbar-mihivai-item navbar-mihivai-link" %>
      <%= link_to "Contact", "/", class: "navbar-mihivai-item navbar-mihivai-link" %>
      <% if user_signed_in? %>
        <%= link_to t(".sign_out", default: "Log out"), destroy_user_session_path, method: :delete , class: "navbar-mihivai-item navbar-mihivai-link"%>
      <% else %>
        <%= link_to t(".sign_in", default: "Login"), new_user_session_path , class: "navbar-mihivai-item navbar-mihivai-link"%>
      <% end %>
    </div>
  </div>

  <div class="d-block d-md-none">
    <div class="navbar-dropdown">
      <input id="toggle" type="checkbox"/>
      <label class="hamburger" for="toggle">
        <div class="top"></div>
        <div class="meat"></div>
        <div class="bottom"></div>
      </label>

      <div class="nav">
        <div class="nav-wrapper">
          <nav class= "d-flex flex-column">
            <%= link_to "Accueil", root_path, class: "navbar-link" %>
            <% if user_signed_in? %>
              <%= link_to "Se Déconnecter", destroy_user_session_path, class: "navbar-link", method: :delete %>
            <% else %>
              <%= link_to "Créer un Compte", new_user_registration_path, class: "navbar-link" %>
              <%= link_to "Se Connecter", new_user_session_path,  class: "navbar-link" %>
            <% end %>
          </nav>
        </div>
      </div>
    </div>

  </div>
</div>

<div style="height: 70px;"></div>

HTML
end

def add_footer
<<-HTML
<div class="footer d-flex justify-content-between align-items-center">
  <div class="footer-links">
  </div>
  <div class="footer-copyright d-flex flex-column">
    © 2018 Your Domain
    <%= link_to legal_path do %>
      Mentions légales
    <% end %>
    <%= link_to "https://www.mihivai.com/", target: "_blank" do %>
      Site réalisé par Mihivai
    <% end %>
  </div>
</div>
HTML
end

# Custom Seed
file 'lib/tasks/custom_seed.rake', <<-RUBY
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
  config.exceptions_app = ->(env) {
    ErrorsController.action(:show).call(env)
  }
RUBY


# ERRORS
file 'app/controllers/errors_controller.rb', <<-RUBY
class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized
  def show
    @exception = request.env["action_dispatch.exception"]
    @status_code = @exception.try(:status_code) ||
                  ActionDispatch::ExceptionWrapper.new(
                    request.env, @exception
                  ).status_code

    render view_for_code(@status_code), status: @status_code
  end

  private

  def view_for_code(code)
    supported_error_codes.fetch(code, "404")
  end

  def supported_error_codes
    {
      403 => "403",
      404 => "404",
      500 => "500"
    }
  end
end
RUBY

run 'mkdir -p app/views/errors'

file 'app/views/errors/404.html.erb', <<-HTML
<%= render 'errors/template' %>
HTML

file 'app/views/errors/500.html.erb', <<-HTML
<%= render 'errors/template' %>
HTML

file 'app/views/errors/_template.html.erb', <<-HTML
<div class="page-min-height py-50px">
  <div class="navbar-height"></div>
  <div class="container">
    <div class="mw-58">
      <h1 class="mb-2pc">Désolé, cette page n’est plus disponible.</h1>
      <%= link_to "Aller à l'accueil du site", root_path, class: "btn btn-primary" %>
    </div>
  </div>
</div>
HTML



environment generators

environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }", env: 'development'
environment "config.action_mailer.delivery_method = :letter_opener", env: 'development'

environment "config.action_mailer.default_url_options = { host: 'your-production-url.com' }", env: 'production'

# Staging
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/config/staging.rb > config/environments/staging.rb'


# SCSS

#components
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/scss/components/utilities.scss > app/assets/stylesheets/components/_utilities.scss'
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/scss/components/navbar.scss > app/assets/stylesheets/components/_navbar.scss'
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/scss/components/footer.scss > app/assets/stylesheets/components/_footer.scss'
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/scss/components/flashes.scss > app/assets/stylesheets/components/_flashes.scss'
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/scss/components/index.scss > app/assets/stylesheets/components/_index.scss'


# config
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/scss/config/sizing.scss > app/assets/stylesheets/config/_sizing.scss'
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/scss/config/fonts.scss > app/assets/stylesheets/config/_fonts.scss'
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/scss/config/bootstrap_variables.scss > app/assets/stylesheets/config/_bootstrap_variables.scss'
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/scss/config/colors.scss > app/assets/stylesheets/config/_colors.scss'



run 'rm app/assets/stylesheets/application.css'
file 'app/assets/stylesheets/application.scss', <<-CSS
@import "config/fonts";
@import "config/colors";
@import "config/bootstrap_variables";

// External libraries
@import "bootstrap";
@import "config/sizing";

// Your CSS partials
@import "components/index";
CSS


# Layout
file 'app/views/layouts/_google_analytics.html.erb',
  add_google_analytics

run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.erb',
  add_layout

add_flash

file 'app/views/shared/_footer.html.erb',
  add_footer

run 'rm public/500.html'
file 'public/500.html',
  update_error_page(500)

run 'rm public/404.html'
file 'public/404.html',
  update_error_page(404)

run 'rm public/422.html'
file 'public/422.html',
  update_error_page(422)


file 'app/views/shared/_navbar.html.erb',
  add_navbar

run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/images/logo.png > app/assets/images/logo.png'
run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/images/logo.png > public/logo.png'

run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/images/banner.png > app/assets/images/banner.png'


# README
########################################
markdown_file_content = <<-MARKDOWN
Rails app generated with MihiVai template.
MARKDOWN
file 'README.md', markdown_file_content, force: true



after_bundle do
  run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"
  run "bin/rails db:drop"
  run "bin/rails db:create"
  run "bin/rails db:migrate"


  run "bin/rails generate simple_form:install --bootstrap"

   append_file "config/importmap.rb", <<~RUBY
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.1.3/dist/js/bootstrap.esm.js"
pin "@popperjs/core", to: "https://unpkg.com/@popperjs/core@2.11.2/dist/esm/index.js"
  RUBY

append_file "app/javascript/application.js", <<~JS
import "bootstrap"
JS

  run "bin/rails generate devise:install"
  run "bin/rails generate devise User"
  run "bin/rails generate devise:views"

  run "bin/rails db:migrate"

  run "bin/rails generate pundit:install"

  run "bin/rails generate draper:install"


  # devise
  run 'rm config/initializers/devise.rb'
  run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/config/devise.rb > config/initializers/devise.rb'

  run 'rm app/views/devise/sessions/new.html.erb'
  run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/views/devise/sessions/new.html.erb > app/views/devise/sessions/new.html.erb'

  run 'rm app/views/devise/registrations/new.html.erb'
  run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/views/devise/registrations/new.html.erb > app/views/devise/registrations/new.html.erb'

  run 'rm app/views/devise/registrations/edit.html.erb'
  run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/views/devise/registrations/edit.html.erb > app/views/devise/registrations/edit.html.erb'


  run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/config/locales/devise.fr.yml > config/locales/devise.fr.yml'


  # rack attack
  if File.exist?('config/initializers/rack_attack.rb')
    run "rm config/initializers/rack_attack.rb"
  end
  run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/config/rack_attack.rb > config/initializers/rack_attack.rb'

  # recaptcha
  run 'mkdir -p app/controllers/users'
  run 'curl -L https://raw.githubusercontent.com/Mihivai/rails-template/master/sessions_controller.rb > app/controllers/users/sessions_controller.rb'

  # active admin
  if yes?("Would you like to install ActiveAdmin ?")
    install_active_admin
  else
    generate_application_controller_without_admin
  end

  # postmark
  install_postmark if yes?("Would you like to install Postmark ?")

  run "bin/rails generate controller pages home --skip-routes --to-test-framework"

  # Routes
  ########################################
  route 'root to: "pages#home"'
  route "get '/legal', to: 'pages#legal', as: 'legal'"


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


     # Creation des Meta
  ########################################

file 'config/meta.yml', <<-YAML
meta_product_name: "Product Name"
meta_title: "Product name - Product tagline"
meta_description: "Relevant description"
meta_image: "logo.png" # should exist in `app/assets/images/`
YAML

file 'config/initializers/default_meta.rb', <<-RUBY
DEFAULT_META = YAML.load_file(Rails.root.join("config/meta.yml"))
RUBY


file 'app/helpers/meta_tags_helper.rb', <<-RUBY
module MetaTagsHelper
  def meta_title
    content_for?(:meta_title) ? content_for(:meta_title) : DEFAULT_META["meta_title"]
  end

  def meta_description
    content_for?(:meta_description) ? content_for(:meta_description) : DEFAULT_META["meta_description"]
  end

  def meta_image
    meta_image = (content_for?(:meta_image) ? content_for(:meta_image) : DEFAULT_META["meta_image"])
    # little twist to make it work equally with an asset or a url
    meta_image.starts_with?("http") ? meta_image : image_url(meta_image)
  end

  # def meta_keywords
  #   content_for?(:meta_keywords) ? content_for(:meta_keywords) : DEFAULT_META["meta_keywords"]
  # end
end
RUBY
  # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit of Mihivai App'"
end
