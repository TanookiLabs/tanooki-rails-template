# frozen_string_literal: true

# Tanooki Rails Kickoff Template

RAILS_REQUIREMENT = ">= 5.2.1"
RUBY_REQUIREMENT = ">= 2.5.2"
REPOSITORY_PATH = "https://raw.githubusercontent.com/TanookiLabs/tanooki-rails-template/master"
$using_sidekiq = false

def git_proxy(**args)
  git args if $use_git
end

def git_proxy_commit(msg)
  git_proxy add: "."
  git_proxy commit: %( -m "#{msg}" )
end

def run_template!
  assert_minimum_rails_and_ruby_version!
  $use_git = yes?("Do you want to add git commits (recommended)")

  git_proxy_commit "Initial commit"

  after_bundle do
    git_proxy_commit "Commit after bundle"
    run "bin/spring stop"
  end

  setup_sidekiq
  setup_email

  add_gems
  main_config_files

  setup_testing
  setup_haml
  setup_sentry
  setup_bullet
  setup_linters

  setup_javascript
  setup_generators

  setup_readme
  create_database

  fix_bundler_binstub

  setup_webpacker

  output_final_instructions

  exit
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
    gem "bullet"
  end

  gem_group :test do
    gem "capybara"
    gem "capybara-selenium"
  end

  git_proxy_commit "Add custom gems"
end

def setup_haml
  after_bundle do
    run "yes | HAML_RAILS_DELETE_ERB=true rake haml:erb2haml"
    git_proxy_commit "Use Haml"
  end
end

def setup_bullet
  inject_into_file "config/environments/development.rb", before: /^end\n/ do
    <<-RB
  config.after_initialize do
    Bullet.enable = true
    # Bullet.sentry = true
    Bullet.alert = false
    Bullet.bullet_logger = true
    Bullet.console = true
    # Bullet.growl = true
    Bullet.rails_logger = true
    # Bullet.add_footer = true
    # Bullet.stacktrace_includes = [ "your_gem", "your_middleware" ]
    # Bullet.stacktrace_excludes = [
    #   "their_gem", "their_middleware", ["my_file.rb", "my_method"], ["my_file.rb", 16..20
    # ]
    # Bullet.slack = {
    #   webhook_url: "http://some.slack.url",
    #   channel: "#default",
    #   username: "notifier"
    #  }
    # Bullet.raise = true
  end
    RB
  end
  git_proxy_commit "Configure Bullet"
end

def output_final_instructions
  msg = <<~MSG
    Template Completed!

    Please review the above output for issues.

    To finish setup, you must prepare Heroku with at minimum the following steps (review the developer guide for further details)
    1) Setup the Skylight ENV variable
    2) Configure Sentry
    3) Add the jemalloc buildpack:
      $ heroku buildpacks:add --index 1 https://github.com/gaffenyc/heroku-buildpack-jemalloc.git
    4) Setup Redis (if using Sidekiq)
    5) Review your README.md file for needed updates
    6) Review your Gemfile for formatting
  MSG

  say msg, :magenta
end

def setup_javascript
  uncomment_lines "bin/setup", "bin/yarn"
  uncomment_lines "bin/update", "bin/yarn"

  git_proxy_commit "Configure Javascript"
end

def setup_sidekiq
  $using_sidekiq = yes?("Do you want to setup Sidekiq?")

  return unless $using_sidekiq

  gem "sidekiq"

  after_bundle do
    insert_into_file "config/application.rb",
      "    config.active_job.queue_adapter = :sidekiq\n\n",
      after: "class Application < Rails::Application\n"

    append_file "Procfile",
      "worker: RAILS_MAX_THREADS=${SIDEKIQ_CONCURRENCY:-25} jemalloc.sh bundle exec sidekiq -t 25\n"

    git_proxy_commit "Setup Sidekiq"
  end
end

def setup_linters
  gem "rubocop", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-thread_safety", require: false
  gem "overcommit"

  after_bundle do
    get "#{REPOSITORY_PATH}/.rubocop.yml", ".rubocop.yml"
    get "#{REPOSITORY_PATH}/.eslintrc.json", ".eslintrc.json"

    pkg_txt = <<-JSON
    "scripts": {
      "lint": "yarn run eslint --ext .js --ext .jsx app/javascript"
    },
    JSON

    insert_into_file "package.json", pkg_txt, before: "\n  \"dependencies\": {"

    create_file ".overcommit.yml" do
      <<~OVERCOMMIT
        PreCommit:
          EsLint:
            enabled: true
            required_executable: "npm"
            command: ["npm", "run", "lint", "-f", "compact"]
          RuboCop:
            enabled: true
            command: ["bundle", "exec", "rubocop"]
      OVERCOMMIT
    end

    run "yarn add eslint --dev"
    run "yarn add eslint-plugin-react --dev"
    run "yarn add babel-eslint --dev"

    git_proxy_commit "Setup styleguide and linters"
  end

  after_bundle do
    bundle_command "exec rubocop -a"
    git_proxy_commit "Autocorrect rubocop"

    bundle_command "exec overcommit --install"
    git_proxy_commit "Install overcommit precommit hook"
  end
end

def setup_email
  gem 'mta-settings'
end

def create_database
  after_bundle do
    bundle_command "exec rails db:create db:migrate"
    git_proxy_commit "Create and migrate database"
  end
end

def fix_bundler_binstub
  after_bundle do
    run "bundle binstubs bundler --force"
    git_proxy_commit "Fix bundler binstub\n\nhttps://github.com/rails/rails/issues/31193"
  end
end

def setup_sentry
  initializer "sentry.rb", <<~RB
    Raven.configure do |config|
      config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

      # consider async reporting: https://github.com/getsentry/raven-ruby#async

      # config.transport_failure_callback = lambda { |event|
      #   AdminMailer.email_admins("Oh god, it's on fire!", event).deliver_later
      # }
    end
  RB

  inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
    <<-RB
  before_action :set_raven_context

  private

  def set_raven_context
    # Uncomment when user is setup:
    # Raven.user_context(id: current_user.id) if current_user
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
    RB
  end

  git_proxy_commit "Setup Sentry"
end

def setup_readme
  remove_file "README.md"
  get "#{REPOSITORY_PATH}/templates/README.md", "README.md"
  unless $using_sidekiq
    gsub_file "README.md", /### Sidekiq.*###/, "###"
    gsub_file "README.md", /^.*Sidekiq.*\n/, ""
  end

  git_proxy_commit "Add README"
end

def setup_testing
  after_bundle do
    bundle_command "exec rails generate rspec:install"
    run "bundle binstubs rspec-core"
    git_proxy_commit "RSpec install"

    create_file "spec/support/chromedriver.rb", <<~RB
      require "selenium/webdriver"

      Capybara.register_driver :chrome do |app|
        Capybara::Selenium::Driver.new(app, browser: :chrome)
      end

      Capybara.register_driver :headless_chrome do |app|
        capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
          chromeOptions: { args: %w[headless disable-gpu] }
        )

        Capybara::Selenium::Driver.new(
          app,
          browser: :chrome,
          desired_capabilities: capabilities
        )
      end

      Capybara.javascript_driver = :headless_chrome
    RB

    create_file "spec/lint_spec.rb", <<~RB
      # consider switching to rake task in the future: https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#linting-factories
      require "rails_helper"
      RSpec.describe "Factories" do
        it "lints successfully" do
          FactoryBot.lint
        end
      end
    RB

    uncomment_lines "spec/rails_helper.rb", /Dir\[Rails\.root\.join/

    gsub_file "spec/spec_helper.rb", "=begin\n", ""
    gsub_file "spec/spec_helper.rb", "=end\n", ""

    comment_lines "spec/rails_helper.rb", "config.fixture_path ="

    insert_into_file "spec/rails_helper.rb",
      "  config.include FactoryBot::Syntax::Methods\n\n",
      after: "RSpec.configure do |config|\n"

    insert_into_file "spec/rails_helper.rb",
      "require \"capybara/rails\"\n",
      after: "Add additional requires below this line. Rails is not loaded until this point!\n"

    git_proxy_commit "Finish setting up testing"
  end
end

def main_config_files
  insert_into_file "config/database.yml", after: "default: &default\n" do
    <<-YML
  reaping_frequency: <%= ENV["DB_REAP_FREQ"] || 10 %> # https://devcenter.heroku.com/articles/concurrency-and-database-connections#bad-connections
  connect_timeout: 1 # raises PG::ConnectionBad
  checkout_timeout: 1 # raises ActiveRecord::ConnectionTimeoutError
  variables:
    statement_timeout: 10000 # manually override on a per-query basis
    YML
  end

  uncomment_lines "config/puma.rb", "workers ENV.fetch"
  uncomment_lines "config/puma.rb", /preload_app!$/

  create_file "Procfile", "web: jemalloc.sh bundle exec puma -C config/puma.rb\nrelease: bundle exec rake db:migrate\n"

  get "#{REPOSITORY_PATH}/.editorconfig", ".editorconfig"

  append_file ".gitignore", <<~GITIGNORE

    spec/examples.txt

    # TODO Comment out this rule if environment variables can be committed
    .env
    .env.development.local
    .env.local
    .env.test.local
  GITIGNORE

  git_proxy_commit "Setup config files"
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

def setup_generators
  initializer "generators.rb", <<~EOF
    Rails.application.config.generators do |g|
      # use UUIDs by default
      g.orm :active_record, primary_key_type: :uuid

      # limit default generation
      g.test_framework(
        :rspec,
        fixtures: true,
        view_specs: false,
        controller_specs: false,
        routing_specs: false,
        request_specs: false,
      )

      # prevent generating js/css/helper files
      g.assets false
      g.helper false

      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end
  EOF

  git_proxy_commit "Configured generators (UUIDs, less files)"
end

def setup_webpacker
  if yes?("Setup webpacker? (skip this if you removed --webpack)")
    bundle_command "exec rails webpacker:install"
    git_proxy_commit "Initialized webpacker"
  end
end

run_template!
if yes?("Is this template being run on an existing application? (usually no)")
  run_after_bundle_callbacks
end
