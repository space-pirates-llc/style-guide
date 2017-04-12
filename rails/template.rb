def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

gem 'locale_kit'
gem 'rails-i18n'
gem 'slim-rails'
gem 'premailer-rails'
gem 'meta-tags'
gem 'sitemap_generator'
gem 'canonical-rails'

gem_group :development do
  gem 'parser', "~> #{RUBY_VERSION}.x", require: false
  gem 'rubocop', require: false
  gem 'letter_opener'
  gem 'guard', require: false
  gem 'guard-bundler', require: false
  gem 'guard-rails', require: false
  gem 'guard-rspec', require: false
  gem 'spring-commands-rspec', require: false
  gem 'brakeman', require: false
end

gem_group :development, :test do
  gem 'factory_girl_rails'
  gem 'rspec-rails'
end

gem_group :test do
  gem 'database_cleaner'
  gem 'ffaker'
  gem 'rspec-power_assert'
  gem 'simplecov', require: false
end

initializer 'i18n.rb', <<-CODE
Rails.application.config.tap do |config|
  config.i18n.available_locales = %i[ja en]
  config.i18n.fallbacks = %i[ja en]
  config.i18n.default_locale = :ja
end
CODE

initializer 'meta_tags.rb', <<-CODE
MetaTags.configure do |config|
  config.title_limit = 70
  config.description_limit = 160
  config.keywords_limit = 255
  config.keywords_separator = ', '
end
CODE

application <<-CODE
config.generators do |generator|
  generator.helper false
  generator.javascripts false
  generator.stylesheets false
  generator.template_engine :slim
end
CODE

environment <<-CODE, env: 'development'
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.default_url_options = { host: 'localhost:3000' }
config.action_controller.asset_host = 'http://localhost:3000'
CODE

after_bundle do
  run 'bundle binstub guard'

  copy_file 'Guardfile'

  append_to_file('.gitignore', %w(/node_modules .DS_Store /coverage /vendor/bundle).join("\n"))

  # Setup locale kit
  run 'rm -rf config/locales'
  generate 'locale_kit:install'

  # Setup rspec
  copy_file '.rspec'
  copy_file 'spec/spec_helper.rb', force: true
  copy_file 'spec/rails_helper.rb', force: true
  copy_file 'spec/support/factory_girl.rb'
  copy_file 'spec/support/database_cleaner.rb'

  environment 'config.public_file_server.enabled = false', env: :test
  environment 'config.eager_load = false', env: :test

  # Setup canonical
  generate 'canonical_rails:install'

  # Setup rails
  copy_file 'app/helpers/application_helper.rb', force: true
  copy_file 'app/views/layouts/application.html.slim'
  run 'rm app/views/layouts/application.html.erb'

  # Cleanup gemfile
  run 'sed -i -e "/^ *#/d" Gemfile'
  run 'sed -i -e "/^$/d" Gemfile'

  # Setup rubocop
  copy_file '.rubocop.yml'
  run 'bundle exec rubocop -a'

  run 'bundle exec spring stop'
end
