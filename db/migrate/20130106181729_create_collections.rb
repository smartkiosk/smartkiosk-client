class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.text     :payment_ids
      t.text     :banknotes
      t.datetime :reported_at
      t.timestamps
    end
  end
end
