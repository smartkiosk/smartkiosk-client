task :console do
  binding.pry
end

task :smartguard do
  exec('bundle exec smartguard --development --app smartkiosk')
end

task :sidekiq do
  exec('bundle exec sidekiq -q pings -q payments -q orders -q sync -q scheduled -r ./app.rb')
end

task :web do
  require 'eventmachine'
  require 'thin'

  EventMachine.run do
    Smartkiosk::Client.run! :server => 'thin', :port => 3000
  end
end