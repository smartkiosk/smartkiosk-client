require 'pry'
require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/reloader'

module Smartkiosk
  class Client < Sinatra::Base
    register Sinatra::ActiveRecordExtension

    configure :development do
      register Sinatra::Reloader
    end

    set :root, Pathname.new(File.expand_path '..', root)
    set :database_file, '../config/services/database.yml'
    set :views, File.join(root, 'app/views')

    def self.load(path)
      require File.join(root, path)
    end

    def self.run!(*args)
      load 'lib/sidekiq'
      Sidekiq.startup!
      super
    end
  end
end

Application = Smartkiosk::Client

%w(uploaders models workers controllers).each do |dir|
  Dir["app/#{dir}/**/*.rb"].each {|file| require_relative File.join('..', file) }
end