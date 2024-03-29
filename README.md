# Tanooki Rails Template

This repository holds the Rails application template referred to in our
[kickoff developer guide][ko].

[ko]: https://github.com/TanookiLabs/developer-guides/blob/master/web/kickoff.md

## Usage

1. Find the [newest version of ruby that heroku supports that has been released for more than 6 months][h] and make sure you're using it (via `ruby --version`)
1. install rails and bundler globally
   ```bash
   gem update --system
   gem install rails --no-document
   gem update bundler
   ```
1. Clone or create a directory for your rails app and move into it
1. Run `rails new` with the template with these commands:
   ```bash
   # make sure you're up to date!
   rails --version 
   rails new example-project-name \
         --database=postgresql \
         --skip-javascript \
         --skip-test \
         --skip-action-mailbox \
         --skip-action-text \
         --skip-jbuilder \
         --template=https://raw.githubusercontent.com/TanookiLabs/tanooki-rails-template/master/template.rb
   ```

- [ ] Clean up Gemfile
- [ ] Refer back to the [kickoff guide][kg] and make sure you've followed the Heroku
      Checklist
- [ ] setup authentication with [devise](https://github.com/heartcombo/devise) if applicable
- [ ] setup authorization with [action policy](https://github.com/palkan/action_policy) if applicable

[h]: https://devcenter.heroku.com/articles/ruby-support#supported-runtimes
[kg]: https://github.com/TanookiLabs/developer-guides/blob/master/rails/kickoff.md
