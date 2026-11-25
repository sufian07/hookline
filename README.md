# Hookline

A small webhook gateway built with Rails 8. It receives webhooks, verifies and stores them, and delivers them to subscribers with retries.

Status: early. See `docs/adr` for decisions.

## Run

    bundle install
    bin/rails db:prepare
    bundle exec rspec
