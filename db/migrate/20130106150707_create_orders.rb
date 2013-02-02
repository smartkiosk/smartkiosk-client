class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.integer  :foreign_id
      t.datetime :foreign_created_at
      t.string   :keyword
      t.text     :args
      t.string   :error
      t.boolean  :acknowledged
      t.boolean  :complete

      t.timestamps
    end
  end
end
