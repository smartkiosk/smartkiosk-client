task :console do
  binding.pry
end

task :smartguard do
  exec('bundle exec smartguard --development --app smartkiosk')
end

task :sidekiq do
  exec('bundle exec sidekiq -q pings -q payments -q orders -q sync -q scheduled -r ./app.rb')
end

task :server do
  require 'eventmachine'
  require 'thin'

  EventMachine.run do
    environment = ENV['ENV'].blank? ? :development : ENV['ENV'].to_sym

    Smartkiosk::Client.run! :server => 'thin',
      :port => 3000,
      :environment => environment
  end
end