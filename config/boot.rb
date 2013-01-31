require 'bundler/setup'
require 'pry'
require 'active_support/all'
require 'sass'
require 'sprockets'
require 'sprockets/sass'
require 'sprockets/helpers'

require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'sinatra/json'

module Smartkiosk
  class Client < Sinatra::Base
    register Sinatra::ActiveRecordExtension

    helpers do
      include Sprockets::Helpers
    end

    configure do
      set :assets_types,  %w(javascripts stylesheets images flash)
      set :root,          Pathname.new(File.expand_path '../..', __FILE__)
      set :sprockets,     Sprockets::Environment.new(root)
      set :database_file, root.join('config/services/database.yml')
      set :views,         [File.expand_path('../../app/views', __FILE__)]

      assets_types.map do |x|
        sprockets.append_path root.join("app/assets/#{x}")
        sprockets.append_path root.join("vendor/assets/#{x}")
      end

      ActiveRecord::Base.include_root_in_json = false
      ActiveRecord::Migrator.migrations_paths = [root.join('db/migrate')]
    end

    configure :development do
      register Sinatra::Reloader

      Sprockets::Helpers.configure do |config|
        config.environment = sprockets
        config.expand = true
      end
    end

    configure :production do
      Sprockets::Helpers.configure do |config|
        config.environment = sprockets
        config.expand = false
        config.digest = true
      end
    end

    def find_template(views, name, engine, &block)
      Array(views).each { |v| super(v.to_s, name, engine, &block) }
    end

    def json(data)
      content_type :json
      data.to_json
    end

    def self.load(path)
      require File.expand_path File.join('../..', path), __FILE__
    end

    def self.load_tasks!
      require "sinatra/activerecord/rake"
      Dir[File.expand_path "../../lib/tasks/*.rb", __FILE__].each {|file| require file}
    end

    def self.load_app!
      load 'lib/smartkiosk/client/logging'
      load 'lib/patches/amqp'
      load 'lib/patches/sidekiq'

      %w(uploaders models workers controllers).each do |dir|
        Dir[File.expand_path "../../app/#{dir}/**/*.rb", __FILE__].each {|file| require file }
      end

      self
    end

    def self.expand!(path)
      set :root, Pathname.new(File.expand_path '../..', path)
      set :database_file, root.join('config/services/database.yml')
      set :views, views + [root.join('app/views')]

      assets_types.map do |x|
        sprockets.append_path root.join("app/assets/#{x}")
        sprockets.append_path root.join("vendor/assets/#{x}")
      end
    end
  end
end

(Application = Smartkiosk::Client).load_app!