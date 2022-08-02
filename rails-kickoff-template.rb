# Tanooki Rails Kickoff Template
#
# References:
# https://github.com/erikhuda/thor
# https://www.rubydoc.info/github/wycats/thor/Thor

RAILS_REQUIREMENT = ">= 7.0.3.1"
RUBY_REQUIREMENT = ">= 3.1.0"
REPOSITORY_PATH = "https://raw.githubusercontent.com/TanookiLabs/tanooki-rails-template/master"

def git_commit_all(msg)
  git add: "."
  git commit: %( -m "#{msg}" )
end

def run_template!
  assert_minimum_rails_and_ruby_version!

  git_commit_all "Initial commit"

  after_bundle do
    git_commit_all "Commit after bundle"
  end

  setup_sidekiq

  add_gems
  main_config_files

  setup_testing
  setup_haml
  setup_sentry
  setup_environments

  setup_generators

  setup_readme
  create_database

  setup_linters

  setup_commit_hooks

  setup_html_emails

  setup_ci

  generate_tmp_dirs

  output_final_instructions
end

def add_gems
  gem "haml-rails"
  gem "sentry-ruby"
  gem "sentry-rails"
  gem "sentry-sidekiq"
  gem "inky-rb", require: "inky"
  gem "premailer-rails"
  gem "sass"
  gem "sidekiq"

  gem_group :development, :test do
    gem "rspec-rails"
    gem "rspec_tap", require: false
    gem "factory_bot_rails"
    gem "dotenv-rails"
    gem "standard"
  end

  gem_group :development do
    gem "letter_opener"
    gem "lefthook"
  end

  gem_group :test do
    gem "capybara"
    gem "capybara-selenium"
  end

  gem_group :production do
    gem "rack-timeout"
  end

  git_commit_all "Add standard tanooki depencies"
end

def setup_haml
  after_bundle do
    run "yes | HAML_RAILS_DELETE_ERB=true rake haml:erb2haml"
    git_commit_all "Use Haml"
  end
end

def setup_environments
  inject_into_file "config/environments/development.rb", before: /^end\n/ do
    <<-RB
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
    RB
  end
  git_commit_all "Configure letter opener in development"

  # gsub_file(
  #   "config/environments/production.rb",
  #   /config\.log_level = :debug/,
  #   'config.log_level = ENV.fetch("LOG_LEVEL", "info").to_sym'
  # )

  # git_commit_all "Make :info the default log_level in production"

  ["development", "test"].each do |env|
    inject_into_file "config/environments/#{env}.rb", before: /^end\n/ do
      "\n  config.action_controller.action_on_unpermitted_parameters = :raise\n"
    end
  end
  git_commit_all "Raise an error when unpermitted parameters in development"
end

def output_final_instructions
  after_bundle do
    msg = <<~MSG
      Template Completed!

      Please review the above output for issues.

      At this point, make sure `bin/dev` spins up your rails app and consider adding

      - authentication: https://github.com/heartcombo/devise
      - authorization: https://github.com/palkan/action_policy
      - api: https://github.com/rmosolgo/graphql-ruby

      To finish setup, you must prepare Heroku with at minimum the following steps (review the developer guide for further details)

      1) Setup Postgres, Redis
      2) Configure Sentry
      3) Review your README.md file for needed updates
    MSG

    say msg, :magenta
  end
end

def setup_sidekiq
  after_bundle do
    insert_into_file "config/application.rb",
      "    config.active_job.queue_adapter = :sidekiq\n\n",
      after: "class Application < Rails::Application\n"

    ["Procfile", "Procfile.dev"].each do |file|
      append_file file, <<~PROCFILE
        worker: RAILS_MAX_THREADS=${SIDEKIQ_CONCURRENCY:-25} bundle exec sidekiq -t 25 -q default -q mailers
      PROCFILE
    end

    git_commit_all "Setup Sidekiq"
  end
end

def setup_linters
  after_bundle do
    create_file ".eslintrc.json", <<~ESLINTRC
      {
        "extends": "react-app"
      }
    ESLINTRC

    pkg_txt = <<-JSON
    "scripts": {
      "lint:check": "eslint 'app/**/*.js'",
      "lint:fix": "eslint --fix 'app/**/*.js'"
    },
    JSON

    insert_into_file "package.json", pkg_txt, before: "\n  \"dependencies\": {"

    # https://www.npmjs.com/package/eslint-config-react-app
    run "yarn add --dev eslint eslint-config-react-app eslint@^8.0.0"

    git_commit_all "Setup styleguide and linters"
  end

  after_bundle do
    bundle_command "exec standardrb --fix"
    git_commit_all "Automatically format code with standard"
  end
end

def setup_commit_hooks
  create_file "lefthook.yml", <<~YML
    # Lefthook - git hook management
    # https://github.com/Arkweid/lefthook
    pre-commit:
      parallel: false
      commands:
        standardrb:
          glob: "{*.rb,*.rake,Gemfile}"
          run: bundle exec standardrb {staged_files} --safe-auto-correct && git add {staged_files}
        eslint:
          glob: "*.{js,jsx,ts,tsx}"
          run:
            yarn eslint {staged_files} --fix && git add {staged_files}
  YML

  append_file ".gitignore", <<~GITIGNORE
    lefthook-local.yml
  GITIGNORE

  git_commit_all "Install lefthook"
end

def create_database
  after_bundle do
    bundle_command "exec rails db:create db:migrate"
    git_commit_all "Create and migrate database"
  end
end

def setup_sentry
  initializer "sentry.rb", <<~RB
    # https://docs.sentry.io/platforms/ruby/guides/rails/
    Sentry.init do |config|
      config.breadcrumbs_logger = [:active_support_logger, :http_logger]

      # To activate performance monitoring, set one of these options.
      # We recommend adjusting the value in production:
      config.traces_sample_rate = 0.5
    end
  RB

  inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
    <<-RB
  before_action :set_sentry_context

  private

  def set_sentry_context
    # Uncomment when user is setup:
    # Sentry.set_user({id: current_user.id, email: current_user.email}) if current_user
    Sentry.configure_scope do |scope|
      scope.set_context("request", {params: params.to_unsafe_h, url: request.url})
    end
  end
    RB
  end

  git_commit_all "Setup Sentry"
end

def setup_readme
  remove_file "README.md"
  create_file "README.md", <<~README
    # #{app_name}

    ### Dependencies

    - ruby, bundler
    - node, yarn
    - postgresql
    - redis
    - chromedriver `brew cask install chromedriver`

    ### Setup

    ```bash
    bin/setup
    bundle exec lefthook install
    ```

    ### Tests

    ```bash
    bundle exec rspec
    ```

    ### Deployment Information

    ### Sidekiq

    Please follow [Sidekiq Best Practices](https://github.com/mperham/sidekiq/wiki/Best-Practices), especially making jobs idempotent and transactional.

    ### Email

    This project is configured with the [mta-settings](https://github.com/tpope/mta-settings) gem for transparent configuration of e-mail based on Heroku environment variables. This supports Sendgrid, Mandrill, Postmark, Mailgun, and Mailtrap ENV variables.

    Note that this means that if you do not want emails to be sent out, you should not have any of these environment variables set (except for Mailtrap).

    ### Coding Style

    This projects uses RuboCop and ESLint to catch errors and keep style consistent.

    It also uses [lefthook][lh] to manage git hooks. Use `git commit --no-verify` to skip checks, or see [./lefthook.yml](./lefthook.yml) for info on how to change its setup.

    [lh]: https://github.com/Arkweid/lefthook

    Making changes to the linter setup? Please share your fixes and make a PR to the [Tanooki template][tt] so future projects may benefit.

    [tt]: https://github.com/TanookiLabs/tanooki-rails-template

    ### Important rake tasks

    _TODO_

    ### Scheduled tasks

    _TODO_

    ### Important ENV variables

    Note that this project uses [dotenv](https://github.com/bkeepers/dotenv) to load `.env` files. Use `.env.development` and `.env.test` to setup _shared_ ENV variables for development and test, and use `.env` files ending in `.local` for variables specific to you.

    Configuring Servers:

    ```
    WEB_CONCURRENCY - Number of Puma workers
    RAILS_MAX_THREADS - Number of threads per Puma worker
    SIDEKIQ_CONCURRENCY - Number of Sidekiq workers
    ```

    [rack-timeout][rt]:

    ```
    RACK_TIMEOUT_SERVICE_TIMEOUT
    RACK_TIMEOUT_WAIT_TIMEOUT
    RACK_TIMEOUT_WAIT_OVERTIME
    RACK_TIMEOUT_SERVICE_PAST_WAIT
    ```

    [rt]: https://github.com/sharpstone/rack-timeout#configuring
  README

  git_commit_all "Add README"
end

def setup_testing
  after_bundle do
    bundle_command "exec rails generate rspec:install"
    run "bundle binstubs rspec-core"
    git_commit_all "RSpec install"

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

    git_commit_all "Finish setting up testing"
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

  create_file "Procfile", <<~PROCFILE
    web: bundle exec puma -C config/puma.rb
    release: bundle exec rake db:migrate
  PROCFILE

  create_file ".editorconfig", <<~EDITORCONFIG
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
  EDITORCONFIG

  append_file ".gitignore", <<~GITIGNORE

    spec/examples.txt

    # TODO Comment out this rule if environment variables can be committed
    .env
    .env.development.local
    .env.local
    .env.test.local
  GITIGNORE

  create_file ".env"
  create_file ".env.sample"

  git_commit_all "Setup config files"
end

def assert_minimum_rails_and_ruby_version!
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)

  unless requirement.satisfied_by?(rails_version)
    exit 1 if no?("This template requires Rails #{RAILS_REQUIREMENT}. You are using #{rails_version}. Continue anyway?")
  end

  requirement = Gem::Requirement.new(RUBY_REQUIREMENT)
  ruby_version = Gem::Version.new(RUBY_VERSION)

  unless requirement.satisfied_by?(ruby_version)
    exit 1 if no?("This template requires Ruby #{RUBY_REQUIREMENT}. You are using #{ruby_version}. Continue anyway?")
  end
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
      g.factory_bot suffix: "factory"
    end
  EOF

  git_commit_all "Configured generators (UUIDs, less files)"
end

def setup_html_emails
  run "yarn add https://github.com/TanookiLabs/foundation-emails.git"

  [".env", ".env.sample"].each do |env_file|
    append_file env_file, <<~ENV
      ASSET_HOST=http://localhost:5100
    ENV
  end

  initializer "inky.rb", <<~RB
    Inky.configure do |config|
      config.template_engine = :haml
    end
  RB

  initializer "action_mailer.rb", <<~RB
    Rails.application.config.action_mailer.asset_host = ENV["ASSET_HOST"]
  RB

  append_file "config/initializers/assets.rb", <<~RB
    Rails.application.config.assets.precompile += %w(email.css)
  RB

  remove_file "app/views/layouts/mailer.html.haml"
  create_file "app/views/layouts/mailer.html.inky", <<~HAML
    !!! Strict
    %html{:xmlns => "http://www.w3.org/1999/xhtml"}
      %head
        %meta{:content => "text/html; charset=utf-8", "http-equiv" => "Content-Type"}/
        %meta{:content => "width=device-width", :name => "viewport"}/
        = stylesheet_link_tag "email"
      %body
        %table.body
          %tr
            %td.center{:align => "center", :valign => "top"}
              %center
                %container
                  %row
                    %columns
                      %br
                      = yield
  HAML

  create_file "app/assets/stylesheets/email.scss", <<~CSS
    // variable references:
    // https://github.com/TanookiLabs/foundation-emails/blob/develop/scss/settings/_settings.scss
    // https://github.com/TanookiLabs/foundation-emails/blob/develop/scss/components/_typography.scss

    // FYI: this is from node_modules, not bundler
    @import "foundation-emails/scss/foundation-emails";
  CSS

  git_commit_all "Setup html emails"
end

# unclear why this is needed, but `heroku local` fails without it
# "No such file or directory @ rb_sysopen - tmp/pids/server.pid"
def generate_tmp_dirs
  empty_directory "tmp/pids"

  create_file "tmp/pids/.keep", ""

  append_file ".gitignore", <<~GITIGNORE
    /tmp/pids/*
    !/tmp/.keep
    !/tmp/pids
    !/tmp/pids/.keep
  GITIGNORE

  git_commit_all "Add empty tmp/pids directory"
end

def setup_ci
  create_file ".github/workflows/rails.yml", <<~GH_ACTIONS
    name: rails
    on: push
    jobs:
      standard:
        runs-on: ubuntu-latest
        steps:
          - name: Checkout code
            uses: actions/checkout@v2
          - name: Set up Ruby
            uses: ruby/setup-ruby@v1
            with:
              bundler-cache: true
          - run: bundle exec standardrb

      rspec:
        runs-on: ubuntu-latest
        services:
          postgres:
            image: postgres
            env:
              POSTGRES_USER: postgres
              POSTGRES_PASSWORD: password
            ports: ["5432:5432"]
            options: >-
              --health-cmd pg_isready
              --health-interval 10s
              --health-timeout 5s
              --health-retries 5

          chrome:
            image: selenium/standalone-chrome:latest
            volumes:
              - /dev/shm:/dev/shm

        steps:
          - name: Checkout code
            uses: actions/checkout@v2

          - name: Set up Ruby
            uses: ruby/setup-ruby@v1
            with:
              bundler-cache: true

          - uses: actions/setup-node@v2
            with:
              cache: "yarn"

          - name: Setup test database
            env:
              RAILS_ENV: test
              DATABASE_URL: "postgres://postgres:password@localhost:5432/#{app_name}_test"
            run: |
              bin/rails db:create
              bin/rails db:migrate

          - name: Compile assets
            env:
              RAILS_ENV: test
            run: |
              yarn install --frozen-lockfile
              bin/rails assets:precompile

          - name: Run tests
            env:
              RAILS_ENV: test
              DATABASE_URL: "postgres://postgres:password@localhost:5432/#{app_name}_test"
            run: bundle exec rspec
  GH_ACTIONS
end

run_template!
