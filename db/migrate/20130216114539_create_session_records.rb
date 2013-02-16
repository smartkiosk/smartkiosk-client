class CreateSessionRecords < ActiveRecord::Migration
  def change
    create_table :session_records do |t|
      t.integer :started_at
      t.integer :upstream
      t.integer :downstream
      t.integer :time

      t.timestamps
    end
  end
end
