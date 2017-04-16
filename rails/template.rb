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
gem 'premailer-rails'

gem_group :development do
  gem 'parser', "~> #{RUBY_VERSION}.x", require: false
  gem 'rubocop', require: false
  gem 'letter_opener'
  gem 'guard', require: false
  gem 'guard-bundler', require: false
  gem 'guard-process', require: false
  gem 'guard-rails', require: false
  gem 'guard-rspec', require: false
  gem 'spring-commands-rspec', require: false
  gem 'brakeman', require: false
  gem 'slim_lint', require: false
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

initializer 'premailer.rb', <<-CODE
Premailer::Rails.config = Premailer::Rails.config.merge(
  line_length: 65,
  remove_ids: false,
  remove_classes: Rails.env.development?,
  remove_comments: Rails.env.development?,
  preserve_styles: Rails.env.development?,
  adapter: :nokogiri
)
CODE

initializer 'webpack.rb', <<-CODE
# frozen_string_literal: true
#
Rails.application.config.assets.precompile << %r{(^[^_\/]|\/[^_])[^\/]*(\.js|\.css)$}
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

append_to_file '.gitignore', <<-CODE
/node_modules
.DS_Store
/coverage
/vendor/bundle
!.envrc
CODE

# Fix runtime version
create_file '.ruby-version', RUBY_VERSION + "\n"
create_file '.node-version', `node -v`

copy_file 'bin/setup', force: true

template 'README.md.erb', 'README.md', force: true

after_bundle do
  # Setup direnv
  template '.envrc.tpl', '.envrc'
  run 'direnv allow'

  # Setup guard
  run 'bundle binstub guard'
  copy_file 'Guardfile'

  # Setup locale kit
  run 'rm -rf config/locales'
  generate 'locale_kit:install'
  template 'app/locales/meta.yml'

  # Setup rspec
  copy_file '.rspec'
  copy_file 'spec/spec_helper.rb', force: true
  copy_file 'spec/rails_helper.rb', force: true
  copy_file 'spec/support/factory_girl.rb'
  copy_file 'spec/support/database_cleaner.rb'

  # for coverage
  environment 'config.public_file_server.enabled = false', env: :test
  environment 'config.eager_load = false', env: :test

  # Setup canonical
  generate 'canonical_rails:install'

  # Setup rails
  copy_file 'app/helpers/application_helper.rb', force: true
  copy_file 'app/views/layouts/application.html.slim'
  run 'rm app/views/layouts/application.html.erb'
  run 'mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss'
  copy_file 'app/frontends/application.js'
  run 'rm app/assets/javascripts/application.js'
  run 'touch app/assets/javascripts/.keep'

  # Cleanup gemfile
  run 'sed -i "" -e "/^ *#/d" Gemfile'
  run 'sed -i "" -e "/^$/d" Gemfile'

  # Setup yarn
  template 'package.json'
  template 'gulpfile.js'
  copy_file 'config/webpack.js'
  template '.eslintrc.js'
  run 'yarn install'

  # Setup slim lint
  copy_file '.slim-lint.yml'
  run 'bundle binstub slim_lint'
  run './bin/slim-lint'

  # Setup rubocop
  copy_file '.rubocop.yml'
  run 'bundle binstub rubocop'
  run './bin/rubocop -a'

  # Stop spring
  run 'bundle exec spring stop'
end
