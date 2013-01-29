require 'pry'
require 'active_support/all'
require 'sass'
require 'sprockets'
require 'sprockets/sass'

require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'sinatra/json'

require_relative 'environment'

module Smartkiosk
  class Client < Sinatra::Base
    register Sinatra::ActiveRecordExtension

    configure :development do
      register Sinatra::Reloader
    end

    set :assets_types,  %w(javascripts stylesheets images)
    set :root,          Pathname.new(File.expand_path '../..', __FILE__)
    set :assets,        Sprockets::Environment.new(root)
    set :database_file, '../config/services/database.yml'
    set :views,         [File.expand_path('../../app/views', __FILE__)]

    assets_types.map do |x|
      assets.append_path root.join("app/assets/#{x}")
      assets.append_path root.join("vendor/assets/#{x}")
    end

    use Module.new {
      def self.new(app)
        Rack::Builder.new(app) do
          map('/assets') { run Smartkiosk::Client.assets }
        end
      end
    }

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

    def self.run!(*args)
      load 'lib/sidekiq'
      Sidekiq.startup!
      super
    end

    def self.load_tasks!
      require "sinatra/activerecord/rake"
      Dir[File.expand_path "../../lib/tasks/*.rb", __FILE__].each {|file| require file}
    end

    def self.load_app!
      %w(uploaders models workers controllers).each do |dir|
        Dir[File.expand_path "../../app/#{dir}/**/*.rb", __FILE__].each {|file| require file }
      end
    end

    def self.expand!(path)
      set :root, Pathname.new(File.expand_path '../..', path)
      set :database_file, root.join('config/services/database.yml')
      set :views, views + [root.join('app/views')]

      assets_types.map do |x|
        assets.append_path root.join("app/assets/#{x}")
        assets.append_path root.join("vendor/assets/#{x}")
      end
    end
  end
end

Application = Smartkiosk::Client
Application.load_app!