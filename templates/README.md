# PROJECT_NAME

### Services used

- Postgresql
- [Skylight](https://www.skylight.io/) (performance monitoring)
- Sentry (exception reporting)
- Redis (required for Sidekiq)

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

### Sidekiq

This project uses Sidekiq to run background jobs and ActiveJob is configured to use Sidekiq. It is recommended to use ActiveJob to create jobs for simplicity, unless the performance overhead of ActiveJob is an issue.

Remember to follow the [Sidekiq Best Practices](https://github.com/mperham/sidekiq/wiki/Best-Practices), especially making jobs idempotent and transactional. If you are using ActiveJob, the first best practice is _less_ relevant because of Rails GlobalID.

### Email

This project is configured with the [mta-settings](https://github.com/tpope/mta-settings) gem for transparent configuration of e-mail based on Heroku environment variables. This supports Sendgrid, Mandrill, Postmark, Mailgun, and Mailtrap ENV variables.

Note that this means that if you do not want emails to be sent out, you should not have any of these environment variables set (except for Mailtrap).

### Coding Style / Organization

This projects uses RuboCop and ESLint to enforce coding style.

It also uses the [overcommit gem](https://github.com/brigade/overcommit) to handle pre-commit checks of code. It is recommended to find a way to automatically correct things like layout and formatting in your editor or otherwise. `rubocop -a` and `prettier` are two recommended approaches for this. Overcommit also checks your commit message using the `commit-msg` hook.

If you need to commit despite the precommit warning, you may use, `no-verify` or SKIP the particular test:

`SKIP=RuboCop git commit` or `git commit --no-verify`

If you find yourself changing your configuration, please consider submitting a request to the Tanooki [template](https://github.com/TanookiLabs/tanooki-rails-template).

### Important rake tasks

### Scheduled tasks

### Important ENV variables

Configuring Servers:
`WEB_CONCURRENCY` - Number of Puma workers
`RAILS_MAX_THREADS` - Number of threads per Puma worker
`SIDEKIQ_CONCURRENCY` - Number of Sidekiq workers

`rack-timeout` ENV variables and defaults
service_timeout:   15     # RACK_TIMEOUT_SERVICE_TIMEOUT
wait_timeout:      30     # RACK_TIMEOUT_WAIT_TIMEOUT
wait_overtime:     60     # RACK_TIMEOUT_WAIT_OVERTIME
service_past_wait: false  # RACK_TIMEOUT_SERVICE_PAST_WAIT

Note that this project uses [dotenv](https://github.com/bkeepers/dotenv) to load `.env` files. Use `.env.development` and `.env.test` to setup *shared* ENV variables for development and test, and use `.env` files ending in `.local` for variables specific to you.
