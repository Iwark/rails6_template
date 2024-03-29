def get_remote(src, dest = nil)
  dest ||= src
  repo = 'https://raw.github.com/Iwark/rails6_template/master/files/'
  remote_file = repo + src
  remove_file dest
  get(remote_file, dest)
end

# アプリ名の取得
@app_name = app_name

@repo = ask("Type github repository name ex: Iwark/rails6_template")

# .tool_versions
get_remote('tool-versions', '.tool-versions')

# gitignore
get_remote('gitignore', '.gitignore')

# Gemfile
get_remote('Gemfile')

# Database
if yes?('use PostgreSQL?(y/n)')
  gsub_file 'Gemfile', /^gem\s\'sqlite3\'/, 'gem \'pg\''
  get_remote('config/database.yml.example', 'config/database.yml')
  gsub_file "config/database.yml", /myapp/, @app_name
end

# install gems
run 'bundle install --path vendor/bundle --jobs=4'

# Fix pesky hangtime
run "spring stop"

# Simple Form
generate("simple_form:install --bootstrap")

# Devise
generate("devise:install")
get_remote('config/locales/devise.en.yml')
get_remote('config/locales/devise.ja.yml')
gsub_file "config/initializers/devise.rb", /'please-change-me-at-config-initializers-devise@example.com'/, '"no-reply@#{Settings.domain}"'

# create db
run 'bundle exec rails db:create'

# annotate gem
run 'rails g annotate:install'

# webpacker install
run 'rails webpacker:install'

# set config/application.rb
application  do
  %q{
    # Set timezone
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local
    # 日本語化
    I18n.available_locales = [:en, :ja]
    I18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
    # generatorの設定
    config.generators do |g|
      g.orm :active_record
      g.template_engine :slim
      g.test_framework  :rspec, :fixture => true
      g.view_specs false
      g.controller_specs false
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end
    # libファイルの自動読み込み
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
  }
end

# For Bullet (N+1 Problem)
insert_into_file 'config/environments/development.rb',%(
  config.after_initialize do
    Bullet.enable = true # Bulletプラグインを有効
    Bullet.alert = true # JavaScriptでの通知
    Bullet.bullet_logger = true # log/bullet.logへの出力
    Bullet.console = true # ブラウザのコンソールログに記録
    Bullet.rails_logger = true # Railsログに出力
  end
), after: 'config.assets.debug = true'

# SES
insert_into_file 'config/environments/production.rb',%(
  config.action_mailer.default_url_options = {
    protocol: 'https',
    host: Settings.domain,
  }
  config.action_mailer.delivery_method = :ses
), after: 'config.action_mailer.perform_caching = false'

# Japanese locale
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

# erb to slim
run 'gem install html2slim'
run 'bundle exec erb2slim -d app/views'
gsub_file 'app/views/layouts/application.html.slim', 'stylesheet_link_tag', 'stylesheet_pack_tag'

# fontawesome
run 'yarn add @fortawesome/fontawesome-free'
get_remote('app/javascript/packs/application.js')
get_remote('app/javascript/stylesheets/application.scss')
get_remote('app/javascript/stylesheets/reset.scss')
get_remote('app/assets/config/manifest.js')

# Whenever
get_remote('config/schedule.rb')

# Capistrano
get_remote('Capfile')

# pryrc
get_remote('pryrc', '.pryrc')

# Rubocop
get_remote('rubocop.yml', '.rubocop.yml')

# Deploy
get_remote('config/deploy.rb.example', 'config/deploy.rb')
gsub_file "config/deploy.rb", /my_repo/, @repo
gsub_file "config/deploy.rb", /myapp/, @app_name
run 'mkdir config/deploy'
get_remote('config/deploy/production.rb.example', 'config/deploy/production.rb')
gsub_file "config/deploy/production.rb", /myapp/, @app_name

# Unicorn
run 'mkdir -p lib/capistrano/tasks'
get_remote('config/unicorn.rb')
get_remote('lib/capistrano/tasks/unicorn.rake')

# Kaminari config
generate("kaminari:config")

# Rspec
generate("rspec:install")
run "echo '--color -f d' > .rspec"

# Guard
get_remote('Guardfile')

# Settings
run 'mkdir config/settings'
get_remote('config/settings/development.yml.example', 'config/settings/development.yml')
get_remote('config/settings/production.yml.example', 'config/settings/production.yml')
get_remote('config/settings/test.yml.example', 'config/settings/test.yml')
get_remote('config/settings.yml.example', 'config/settings.yml')
gsub_file "config/settings/development.yml", /myapp/, @app_name
gsub_file "config/settings/production.yml", /myapp/, @app_name
gsub_file "config/settings/test.yml", /myapp/, @app_name
gsub_file "config/settings.yml", /myapp/, @app_name

# AWS
get_remote('config/initializers/aws.rb')

# carrierwave
get_remote('config/initializers/carrierwave.rb')

# lograge
get_remote('config/initializers/lograge.rb')

# okcomputer
get_remote('config/initializers/okcomputer.rb')
get_remote('config/locales/okcomputer.en.yml')
get_remote('config/locales/okcomputer.ja.yml')

# git
git
git :init
git add: '.'
git commit: "-a -m 'rails new #{@app_name} -m https://raw.githubusercontent.com/Iwark/rails6_template/master/app_template.rb'"
