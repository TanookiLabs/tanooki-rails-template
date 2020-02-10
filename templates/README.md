# PROJECT_NAME

### Dependencies

- ruby, bundler
- node, yarn
- postgresql
- redis (when using sidekiq)
- jemalloc `brew install jemalloc`
- chromedriver `brew cask install chromedriver`

### Setup

```bash
bin/setup
```

### Tests

```bash
bin/rspec
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

### Coding Style

This projects uses RuboCop and ESLint to catch errors and keep style consistent.

It also uses [lefthook][lh] to manage git hooks. Use `git commit --no-verify` to skip checks, or see [./lefthook.yml](./lefthook.yml) for info on how to change its setup.

[lh]: https://github.com/Arkweid/lefthook

Making changes to the linter setup? Please share your fixes and make a PR to the [Tanooki template][tt] so future projects may benefit.

[tt]: https://github.com/TanookiLabs/tanooki-rails-template

### Important rake tasks

### Scheduled tasks

### Important ENV variables

Configuring Servers:

```
WEB_CONCURRENCY - Number of Puma workers
RAILS_MAX_THREADS - Number of threads per Puma worker
SIDEKIQ_CONCURRENCY - Number of Sidekiq workers
```

rack-timeout:

```
RACK_TIMEOUT_SERVICE_TIMEOUT
RACK_TIMEOUT_WAIT_TIMEOUT
RACK_TIMEOUT_WAIT_OVERTIME
RACK_TIMEOUT_SERVICE_PAST_WAIT
```

refer to [rack-timeout][rt] for default values

[rt]: https://github.com/sharpstone/rack-timeout#configuring

Note that this project uses [dotenv](https://github.com/bkeepers/dotenv) to load `.env` files. Use `.env.development` and `.env.test` to setup _shared_ ENV variables for development and test, and use `.env` files ending in `.local` for variables specific to you.
