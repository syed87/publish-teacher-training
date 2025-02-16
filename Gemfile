source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 3.1.0"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "7.0.4"

# Use PostgreSQL as the database for Active Record
gem "pg"

# Authorisation
gem "pundit"

# Use Puma as the app server
gem "puma", "~> 6.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.1.0", require: false

# Canonical meta tag
gem "canonical-rails"

# Decorate logic to keep it out of the views and helper methods
gem "draper"

# Custom attributes for endpoints
gem "active_model_serializers"

# Pagination for frontend
gem "kaminari"

# Pagination for API
gem "pagy", "~> 5.10"

# JSON:API Ruby Client
gem "jsonapi-rails", github: "DFE-Digital/jsonapi-rails"
gem "jsonapi-rb"

# Access jsonb attributes like normal ActiveRecord model attributes
gem "jsonb_accessor"

# Sending exceptions to sentry
gem "sentry-rails"
gem "sentry-ruby"
gem "sentry-sidekiq"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# For encoding/decoding web token used for authentication
gem "jwt"

# Formalise config settings with support for env vars
gem "config"

# Build pretty tables in the terminal
#   table_print handles ActiveRecord objects and collections really nicely
gem "table_print"
#   terminal-table is a bit more flexible allowing us to use a headers column
gem "terminal-table"

# For querying third party APIs
gem "faraday"

# UK postcode parsing and validation for Ruby
gem "uk_postcode"

# For change history on provider, courses, sites, etc
gem "audited", "~> 5.0"

# State machine to track users through their onboarding journey
gem "aasm"

# Allows writing of error full_messages for validations that don't start with the attribute name
gem "custom_error_message", git: "https://github.com/DFE-Digital/custom-err-msg.git", ref: "46a24a4"

# Soft delete
gem "discard"

# Gov Notify
gem "govuk_notify_rails"

# Run jobs in the background. Good enough until we know we need more firepower
# (i.e. SideKiq)
gem "sidekiq"
gem "sidekiq-cron"

# Semantic Logger makes logs pretty
gem "rails_semantic_logger"

# Render nice markdown
gem "redcarpet"
gem "rubypants"

# Thread-safe global state
gem "request_store"

# IoC Container
gem "dry-container"

# For geocoding and geographic logic (e.g: filtering sites by ranges)
gem "geokit-rails"

gem "open_api-rswag-api"
gem "open_api-rswag-ui"

gem "pg_search"

# End-user application performance monitoring
gem "skylight"

# govuk styling
gem "govuk-components"
gem "govuk_design_system_formbuilder"

# DfE Sign-In
gem "omniauth", "~> 2.1"
gem "omniauth_openid_connect", "~> 0.4"
gem "omniauth-rails_csrf_protection", "~> 1.0"

# Data integration with BigQuery
gem "google-cloud-bigquery"

# Faster JSON serialization
gem "oj"

# Rails 7 CSS and JS Bundling
gem "cssbundling-rails", "~> 1.1"
gem "jsbundling-rails", "~> 1.0"
gem "sprockets-rails", require: "sprockets/railtie"

# for sending analytics data to the analytics platform
gem "dfe-analytics", github: "DFE-Digital/dfe-analytics", tag: "v1.5.3"

# For running data migrations
gem "data_migrate"

group :production, :qa, :sandbox, :staging do
  gem "cloudfront-rails"
end

group :development, :test do
  # Prettyprint in console
  gem "awesome_print"

  # Better colorized logs
  gem "amazing_print"

  # Help eliminate N+1 queries
  gem "bullet"

  # This is the new way to debug!
  gem "debug"

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri mingw x64_mingw]

  gem "erb_lint"
  gem "rubocop-rails"
  gem "rubocop-rspec"

  # run specs in parallel
  gem "parallel_tests"

  # A little extra console goodness
  gem "pry"
  gem "pry-byebug"
  gem "pry-rails"

  gem "rails-controller-testing"

  gem "rails-erd"

  gem "rb-readline"

  # Enable shorter notation for rspec one-liners
  gem "rspec-its"

  # Test framework
  gem "rspec-rails", "6.0.1"

  # A Ruby static code analyzer and formatter
  gem "rubocop", require: false

  # Make diffs of Ruby objects much more readable
  gem "super_diff"

  # Allow us to freeze time in tests
  gem "timecop"

  gem "open_api-rswag-specs", github: "DFE-Digital/open-api-rswag"

  gem "factory_bot_rails", "~> 6.2"
  gem "fakefs", require: "fakefs/safe"
  gem "faker"
end

group :development do
  # Static analysis
  gem "brakeman"

  gem "listen", ">= 3.0.5", "< 3.8"

  # error handling
  gem "better_errors"
  gem "binding_of_caller"

  # Output scaffold commands based on schema
  gem "schema_to_scaffold"

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-commands-rspec"
  gem "spring-watcher-listen", "~> 2.1.0"

  # Make HTTP requests fun again
  gem "httparty"

  # Run tests automatically
  gem "guard"
  gem "guard-rspec", require: false
  gem "guard-rubocop", require: false
end

group :test do
  gem "database_cleaner"
  gem "jsonapi-rspec"
  gem "rspec_junit_formatter"
  gem "shoulda-matchers", "~> 5.2"
  gem "simplecov", "< 0.22", require: false

  # Page objects
  gem "site_prism", "~> 3.7"

  gem "webmock"

  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 2.15"
  gem "launchy"
end
