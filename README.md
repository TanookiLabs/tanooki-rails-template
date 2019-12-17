[![Build Status](https://semaphoreci.com/api/v1/tanookilabs/tanooki-rails-template/branches/master/badge.svg)](https://semaphoreci.com/tanookilabs/tanooki-rails-template)

# Tanooki Rails Template

This repository holds the Rails application template referred to in our [kickoff developer guide](https://github.com/TanookiLabs/developer-guides/blob/master/web/project-kickoff.md)

### How to use this template

- [ ] Verify that you have the most recent stable Ruby version installed, and are using it

- [ ] Create a directory for your rails app and move into it

- [ ] Run the following commands:

  (Note that you may also use `--webpack=react` or `--webpack=stimulus` during the rails new command if you already know you will be using one of these frameworks)

```bash
gem install rails --no-document
gem update bundler
rails new . -T --skip-coffee --webpack --database=postgresql -m https://raw.githubusercontent.com/TanookiLabs/tanooki-rails-template/master/rails-kickoff-template.rb
```

- [ ] Clean up your Gemfile
- [ ] Refer back to the kickoff guide and make sure you've followed the Heroku Checklist and the Semaphore Checklist

### Reference: Step By Step Process

This section explains the changes made by the template

##### Rails Setup of RSpec

- [ ] Add `gem 'rspec-rails'` to the development and test group of Gemfile

```bash
bundle install
rails generate rspec:install
bundle binstubs rspec-core
```

##### Configuration Files

_config/database.yml_

```yaml
default: &default
  ...
  reaping_frequency: <%= ENV['DB_REAP_FREQ'] || 10 %> # https://devcenter.heroku.com/articles/concurrency-and-database-connections#bad-connections
  connect_timeout: 1 # raises PG::ConnectionBad
  checkout_timeout: 1 # raises ActiveRecord::ConnectionTimeoutError
  variables:
    statement_timeout: 10000 # manually override on a per-query basis
```

_config/puma.rb_

```ruby
# Uncomment this:
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# and this:
preload_app!

# Note that the on_worker_boot suggestions in heroku are outdated for Rails 5.2+!

```

_config/environments/development.rb_

```ruby
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

```

*Procfile*

```
web: jemalloc.sh bundle exec puma -C config/puma.rb
release: bundle exec rake db:migrate
```

_.editorconfig_

```
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
```

Add to `.gitignore`:

```yaml
spec/examples.txt

# dotenv
# TODO Comment out this rule if environment variables can be committed
.env
.env.development.local
.env.local
.env.test.local
```

##### Sidekiq Setup

Add the `sidekiq` gem.

To the _Procfile_, add:

```
worker: RAILS_MAX_THREADS=${SIDEKIQ_CONCURRENCY:-25} jemalloc.sh bundle exec sidekiq -t 25
```

Update `config/application.rb` like this:

```
class Application < Rails::Application
  # ...
  config.active_job.queue_adapter = :sidekiq
end
```

##### Email Setup

Add the `mta-settings` gem

##### Styleguide/Linter Setup

Add the `overcommit` gem and obtain the RuboCop and ESLint configuration files from the Tanooki template. Setup the `overcommit.yml` file to check EsLint and RuboCop. Before finishing setup, install the overcommit hooks: `bundle exec overcommit --install` and then execute `bundle exec rubocop -a` to configure the project with the configured style.

##### Testing Setup

###### Browser Testing

```bash
bundle add "capybara" --group "test"
bundle add "capybara-selenium" --group "test"
```

edit _spec/support/chromedriver.rb_

```ruby
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
```

add to _spec/rails_helper.rb_

```ruby
require 'capybara/rails'
```

###### FactoryBot

```bash
bundle add "factory_bot_rails" --group "development, test"
```

add to _spec/rails_helper.rb_ under RSpec.configure:

```ruby
config.include FactoryBot::Syntax::Methods
```

add to _spec/lint_spec.rb_

```ruby
# consider switching to rake task in the future: https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#linting-factories
require 'rails_helper'
RSpec.describe "Factories" do
  it "lints successfully" do
    FactoryBot.lint
  end
end
```

###### Other RSpec setup

In _spec/spec_helper.rb_, remove the `=begin` and `=end` lines to use the RSpec suggested defaults. Additionally, uncomment the line in _spec/rails_helper.rb_ that automatically loads all of the ruby files in `spec/support`

##### Additional minor gems

###### Haml

```bash
bundle add "haml-rails" &&
HAML_RAILS_DELETE_ERB=true rake haml:erb2haml
```

###### Sentry

```bash
bundle add "sentry-raven"
```

configure _config/initializers/sentry.rb_

```ruby
Raven.configure do |config|
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

  # consider async reporting: https://github.com/getsentry/raven-ruby#async

  # config.transport_failure_callback = lambda { |event|
  #   AdminMailer.email_admins("Oh god, it's on fire!", event).deliver_later
  # }
end
```

configure _app/controllers/application_controller.rb_

```ruby
  before_action :set_raven_context

  private

  def set_raven_context
    # Uncomment when user is setup:
    # Raven.user_context(id: current_user.id) if current_user
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
```

###### Other gems

```bash
bundle add dotenv-rails --group "development, test"
bundle add pry-rails --group "development, test"
bundle add bullet --group "development"
bundle add rack-timeout --group "production"
```

##### Setup a README

Copy and update `templates/README-template.md` to `README.md`
