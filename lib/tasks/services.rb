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
  exec('bundle exec smartkiosk-client')
end