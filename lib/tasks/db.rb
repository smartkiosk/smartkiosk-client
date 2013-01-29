namespace :db do
  task :seed do
    load("db/seeds.rb") if File.exists?("db/seeds.rb")
  end

  task :install do
    ActiveRecord::Base.connection.tables.each do |x|
      ActiveRecord::Base.connection.drop_table x
    end

    Redis.current.flushall
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:seed'].invoke
  end
end