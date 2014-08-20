source 'https://rubygems.org'

gem 'rails', '3.2.19'

gem 'pg'
gem 'rsolr'
gem 'libxml-ruby'
gem 'libxslt-ruby'
gem 'nokogiri'
gem 'memcache-client'

group :test, :development do
  gem 'jettywrapper'
  gem 'debugger'
  gem 'rspec-rails'
  gem 'autotest-rails'
  gem 'metastore-test_data', :github => "dtulibrary/metastore-test_data"
  gem 'sqlite3'
end

group :development do
  gem 'brakeman', '~> 1.9'
  gem 'rails_best_practices'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails', '~> 3.2.1'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
end

# Deploy with Capistrano
gem 'capistrano'

# To use debugger
# gem 'debugger'
