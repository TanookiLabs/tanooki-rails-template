# Tanooki Rails Template

This repository holds the Rails application template referred to in our
[kickoff developer guide][ko].

[ko]: https://github.com/TanookiLabs/developer-guides/blob/master/web/kickoff.md

## Usage

- [ ] Find the [newest version of ruby that heroku supports][h] and make sure you're using it (via `ruby --version`)
- [ ] Clone/create a directory for your rails app and move into it
- [ ] Run `rails new` with the template with these commands:

```bash
gem install rails --no-document
gem update bundler
rails new . -T --webpack --database=postgresql -m https://raw.githubusercontent.com/TanookiLabs/tanooki-rails-template/master/rails-kickoff-template.rb
```

_Note that you may also use `--webpack=react` or `--webpack=stimulus` during the
rails new command if you already know you will be using one of these frameworks_

- [ ] Clean up Gemfile
- [ ] Refer back to the kickoff guide and make sure you've followed the Heroku
      Checklist
      
[h]: https://devcenter.heroku.com/articles/ruby-support#supported-runtimes

[![Build Status](https://semaphoreci.com/api/v1/tanookilabs/tanooki-rails-template/branches/master/badge.svg)](https://semaphoreci.com/tanookilabs/tanooki-rails-template)
