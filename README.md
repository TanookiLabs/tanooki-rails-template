# Tanooki Rails Template

This repository holds the Rails application template referred to in our
[kickoff developer guide][ko].

[ko]: https://github.com/TanookiLabs/developer-guides/blob/master/web/kickoff.md

## Usage

1. Find the [newest version of ruby that heroku supports][h] and make sure you're using it (via `ruby --version`)
1. install rails and bundler globally
   ```bash
   gem install rails --no-document
   gem update bundler
   ```
1. Clone or create a directory for your rails app and move into it
1. Run `rails new` with the template with these commands:
   ```bash
   rails new . \
      --database=postgresql \
      --javascript=webpack \
      --skip-test \
      --skip-action-cable \
      --skip-hotwire \
      --skip-action-mailbox \
      --skip-action-text \
      --skip-hotwire \
      --skip-jbuilder \
      --template=https://raw.githubusercontent.com/TanookiLabs/tanooki-rails-template/master/rails-kickoff-template.rb
   ```

_Note that you may also use `--webpack=react` or `--webpack=stimulus` during the
rails new command if you already know you will be using one of these frameworks_

- [ ] Clean up Gemfile
- [ ] Refer back to the [kickoff guide][kg] and make sure you've followed the Heroku
      Checklist

[h]: https://devcenter.heroku.com/articles/ruby-support#supported-runtimes
[kg]: https://github.com/TanookiLabs/developer-guides/blob/master/rails/kickoff.md
