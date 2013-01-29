source 'https://rubygems.org'

gem 'thin'
gem 'sinatra'
gem 'sinatra-activerecord'
gem 'sinatra-contrib'

gem 'smartkiosk-common',         '0.0.2'

gem 'i18n-js',                   '2.1.2'

gem 'sqlite3',                   '1.3.6'
gem 'pg',                        '0.14.1'
gem 'redis',                     '3.0.2'
gem 'redis-objects',             '0.6.1', :require => 'redis/objects'
gem 'carrierwave',               '0.7.1'

gem 'rest-client',               '1.6.7'
gem 'recursive-open-struct',     '0.2.1'

gem 'haml',                      '3.1.7'
gem 'liquid',                    '2.4.1'
gem 'file-tail',                 '1.0.12'

group :test, :development  do
  gem 'rubyzip',                 '0.9.9'
  gem 'pry',                     '0.9.10'
end

group :hardware do
  gem 'smartware',               '0.2.8'
  gem 'smartguard',              '0.3.7', :path => '../smartguard'
end

group :sidekiq do
  gem 'sidekiq',                 '2.6.5'
  gem 'slim',                    '1.3.4'
  gem 'rufus-scheduler',         '2.0.17'
end
