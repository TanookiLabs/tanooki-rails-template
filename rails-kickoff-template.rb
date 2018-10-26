# Tanooki rails-kickoff-template.rb

RAILS_REQUIREMENT = ">= 5.2.1"
RUBY_REQUIREMENT = ">= 2.5.2"

def run_template!
  assert_minimum_rails_and_ruby_version!

  git add: "."
  git commit: %Q{ -m 'Initial commit' }

  after_bundle do
    git add: "."
    git commit: %Q{ -m 'Commit after bundle' }
    run "bin/spring stop"
  end

  add_gems
  main_config_files

  setup_testing
  setup_haml
  setup_sentry
  setup_bullet

  setup_javascript
  
  setup_readme
  create_database

  fix_bundler_binstub

  output_final_instructions
end

def add_gems
  gem "haml-rails"
  gem "sentry-raven"
  gem "skylight"

  gem_group :production do
    gem "rack-timeout"
  end

  gem_group :development, :test do
    gem "rspec-rails"
    gem "factory_bot_rails"
    gem "dotenv-rails"
    gem "pry-rails"
  end

  gem_group :development do
    gem 'bullet'
  end

  gem_group :test do
    gem "capybara"
    gem "capybara-selenium"
  end

  git add: "."
  git commit: %Q{ -m 'Add custom gems' }
end

def setup_haml
  run "yes | HAML_RAILS_DELETE_ERB=true rake haml:erb2haml"
  git add: "."
  git commit: %Q{ -m 'Use Haml' }
end

def setup_bullet
  inject_into_file 'config/environments/development.rb', before: /^end\n/ do <<-RB

  config.after_initialize do
    Bullet.enable = true
    # Bullet.sentry = true
    Bullet.alert = false
    Bullet.bullet_logger = true
    Bullet.console = true
    # Bullet.growl = true
    Bullet.rails_logger = true
    # Bullet.add_footer = true
    # Bullet.stacktrace_includes = [ 'your_gem', 'your_middleware' ]
    # Bullet.stacktrace_excludes = [ 'their_gem', 'their_middleware', ['my_file.rb', 'my_method'], ['my_file.rb', 16..20] ]
    # Bullet.slack = { webhook_url: 'http://some.slack.url', channel: '#default', username: 'notifier' }
    # Bullet.raise = true
  end
  RB
  end
  git add: "."
  git commit: %Q{ -m 'Configure Bullet' }
end

def output_final_instructions
  after_bundle do
    msg = <<~MSG

    Template Completed!

    Please review the above output for issues.
    
    To finish setup, you must prepare Heroku with the following steps:
    1) Setup the Skylight ENV variable
    2) Configure Sentry
    3) Add the jemalloc buildpack:
      $ heroku buildpacks:add --index 1 https://github.com/mojodna/heroku-buildpack-jemalloc.git

    MSG

    say msg, :magenta
  end

end

def setup_javascript
  uncomment_lines "bin/setup", "system('bin/yarn')"
  uncomment_lines "bin/update", "system('bin/yarn')"

  git add: "."
  git commit: %Q{ -m 'Configure Javascript' }
end

def create_database
  bundle_command "exec rails db:create db:migrate"
  git add: "."
  git commit: %Q{ -m 'Create and migrate database' }
end

def fix_bundler_binstub
  run "bundle binstubs bundler --force"
  git add: "."
  git commit: %Q{ -m "Fix bundler binstub\n\nhttps://github.com/rails/rails/issues/31193" }
end

def setup_sentry
  initializer 'sentry.rb', <<~RB
    Raven.configure do |config|
      config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

      # consider async reporting: https://github.com/getsentry/raven-ruby#async

      # config.transport_failure_callback = lambda { |event|
      #   AdminMailer.email_admins("Oh god, it's on fire!", event).deliver_later
      # }
    end
  RB

  inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do <<-RB
  before_action :set_raven_context

  private

  def set_raven_context
    # Uncomment when user is setup:
    # Raven.user_context(id: current_user.id)
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
  RB
  end
end

def setup_readme
  remove_file 'README.md'
  create_file 'README.md' do <<~MARKDOWN
    # PROJECT_NAME

    ### Services used

    - Postgresql
    - [Skylight](https://www.skylight.io/) (performance monitoring)
    - Sentry (exception reporting)

    ### Local Setup Guide

    Important note: Please setup your local code editor with [EditorConfig](https://editorconfig.org/) for code normalization

    To setup the project for your local environment, please run the included script:

    ```bash
    $ bin/setup
    ```

    ### Running Tests
    
    This project uses RSpec for testing. To run tests:

    ```bash
    $ bin/rspec spec
    ```

    For javascript integration testing, we use Google Chromedriver. You may need to `brew install chromedriver` to get this working!

    ### Heroku configuration

    This project is served from Heroku. It uses jemalloc to more efficiently allocate memory. You must run the following to setup jemalloc:

    ```bash
    heroku buildpacks:add --index 1 https://github.com/mojodna/heroku-buildpack-jemalloc.git
    ```

    ### Deployment Information

    ### Coding Style / Organization

    ### Important rake tasks

    ### Scheduled tasks

    ### Important ENV variables
    
    `rack-timeout` ENV variables and defaults
    service_timeout:   15     # RACK_TIMEOUT_SERVICE_TIMEOUT
    wait_timeout:      30     # RACK_TIMEOUT_WAIT_TIMEOUT
    wait_overtime:     60     # RACK_TIMEOUT_WAIT_OVERTIME
    service_past_wait: false  # RACK_TIMEOUT_SERVICE_PAST_WAIT

    Note that this project uses [dotenv](https://github.com/bkeepers/dotenv) to load `.env` files. Use `.env.development` and `.env.test` to setup *shared* ENV variables for development and test, and use `.env` files ending in `.local` for variables specific to you.

  MARKDOWN
  end

  git add: "."
  git commit: %Q{ -m 'Add README' }
end

def setup_testing
  after_bundle do
    run "bundle exec rails generate rspec:install"
    run "bundle binstubs rspec-core"
    git add: "."
    git commit: %Q{ -m 'RSpec install' }

    create_file "spec/support/chromedriver.rb", <<~RB
      require "selenium/webdriver"

      Capybara.register_driver :chrome do |app|
        Capybara::Selenium::Driver.new(app, browser: :chrome)
      end

      Capybara.register_driver :headless_chrome do |app|
        capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
          chromeOptions: { args: %w(headless disable-gpu) },
        )

        Capybara::Selenium::Driver.new app,
          browser: :chrome,
          desired_capabilities: capabilities
      end

      Capybara.javascript_driver = :headless_chrome
    RB

    create_file "spec/lint_spec.rb", <<~RB
      # consider switching to rake task in the future: https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#linting-factories
      require 'rails_helper'
      RSpec.describe "Factories" do
        it "lints successfully" do
          FactoryBot.lint
        end
      end
    RB

    gsub_file "spec/spec_helper.rb", "=begin\n", ""
    gsub_file "spec/spec_helper.rb", "=end\n", ""

    comment_lines "spec/rails_helper.rb", "config.fixture_path ="

    insert_into_file "spec/rails_helper.rb",
      "  config.include FactoryBot::Syntax::Methods\n\n",
      after: "RSpec.configure do |config|\n"

    insert_into_file "spec/rails_helper.rb",
      "require 'capybara/rails'\n",
      after: "Add additional requires below this line. Rails is not loaded until this point!\n"

    git add: "."
    git commit: %Q{ -m 'Finish setting up testing' }
  end
end

def main_config_files
  insert_into_file "config/database.yml", after: "default: &default\n" do <<-YML
  reaping_frequency: <%= ENV['DB_REAP_FREQ'] || 10 %> # https://devcenter.heroku.com/articles/concurrency-and-database-connections#bad-connections
  connect_timeout: 1 # raises PG::ConnectionBad
  checkout_timeout: 1 # raises ActiveRecord::ConnectionTimeoutError
  variables:
    statement_timeout: 10000 # manually override on a per-query basis
  YML
  end

  uncomment_lines "config/puma.rb", "workers ENV.fetch"
  uncomment_lines "config/puma.rb", /preload_app!$/

  create_file "Procfile", "web: jemalloc.sh bundle exec puma -C config/puma.rb"

  create_file ".editorconfig", <<~CONFIG
    # This file is for unifying the coding style for different editors and IDEs
    # editorconfig.org

    root = true

    [*]
    charset = utf-8
    trim_trailing_whitespace = true
    insert_final_newline = true
    indent_style = space
    indent_size = 2
    end_of_line = lf
  CONFIG

  append_file ".gitignore", <<~GITIGNORE

    spec/examples.txt
  
    # TODO Comment out this rule if environment variables can be committed
    .env
    .env.development.local
    .env.local
    .env.test.local
  GITIGNORE

  git add: "."
  git commit: %Q{ -m 'Setup config files' }
end

def assert_minimum_rails_and_ruby_version!
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)

  requirement = Gem::Requirement.new(RUBY_REQUIREMENT)
  ruby_version = Gem::Version.new(RUBY_VERSION)
  return if requirement.satisfied_by?(ruby_version)

  prompt = "This template requires Ruby #{RUBY_REQUIREMENT}. "\
           "You are using #{ruby_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

run_template!

