source "https://rubygems.org"

ruby "3.4.9"

# =========================================================
# RAILS
# =========================================================

gem "rails", "~> 8.1.0"

# =========================================================
# DATABASE
# =========================================================

gem "pg"

# =========================================================
# SERVER
# =========================================================

gem "puma", ">= 6.4"

# =========================================================
# ASSETS / FRONT
# =========================================================

# Asset pipeline
gem "sprockets-rails"

# Importmap
gem "importmap-rails"

# Hotwire
gem "turbo-rails"
gem "stimulus-rails"

# JSON builder
gem "jbuilder"

# Sass compatible Rails 8
gem "sassc-rails"

# =========================================================
# AUTH
# =========================================================

gem "devise"

# =========================================================
# PAYMENTS
# =========================================================

gem "stripe"

# =========================================================
# PERFORMANCE
# =========================================================

# Faster boot
gem "bootsnap", require: false

# =========================================================
# WINDOWS SUPPORT
# =========================================================

gem "tzinfo-data",
    platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# =========================================================
# DEVELOPMENT
# =========================================================

group :development do
  # Better Rails console / debugging
  gem "web-console"
end

# =========================================================
# DEVELOPMENT + TEST
# =========================================================

group :development, :test do
  # Debugger
  gem "debug",
      platforms: %i[ mri mswin mswin64 mingw x64_mingw ],
      require: "debug/prelude"

  # ENV variables
  gem "dotenv-rails"
end

# =========================================================
# TEST
# =========================================================

group :test do
  # System tests
  gem "capybara"
  gem "selenium-webdriver"
end
