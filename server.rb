require "rubygems"
require "bundler/setup"

require "eventmachine"
require "thin"

require_relative "config/boot"

EventMachine.run do
  Smartkiosk::Client.run! :port => 3000
end
