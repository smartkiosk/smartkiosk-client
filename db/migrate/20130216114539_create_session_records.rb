class CreateSessionRecords < ActiveRecord::Migration
  def change
    create_table :session_records do |t|
      t.string  :message_id
      t.integer :started_at
      t.integer :upstream
      t.integer :downstream
      t.integer :time

      t.timestamps
    end

    add_index :session_records, [ :message_id ], :unique => true
  end
end
