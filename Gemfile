source "https://rubygems.org"

gem "rails", "~> 8.1.4", ">= 8.1.4.1"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"
gem "solid_queue"
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "rspec-rails"
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "webmock"
end
