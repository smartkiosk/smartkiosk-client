root = Pathname.new(File.expand_path '../..', __FILE__)

ActiveRecord::Base.include_root_in_json = false
ActiveRecord::Migrator.migrations_paths = [root.join('db/migrate')]