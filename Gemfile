# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

# Inside the development app, the relative require has to be one level up, as
# the Gemfile is copied to the development_app folder (almost) as is.
base_path = ""
base_path = "../" if File.basename(__dir__) == "development_app"
require_relative "#{base_path}lib/decidim/trusted_ids/version"

DECIDIM_VERSION = Decidim::TrustedIds::DECIDIM_VERSION

gem "decidim", DECIDIM_VERSION
gem "decidim-trusted_ids", path: "."

gem "bootsnap", "~> 1.7"

gem "concurrent-ruby", "1.3.4"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", DECIDIM_VERSION
end

group :development do
  gem "faker"
  gem "letter_opener_web"
  gem "listen"
  gem "rubocop-faker"
  gem "spring"
  gem "spring-watcher-listen"
  gem "web-console"
end

group :test do
  gem "codecov", require: false
end
