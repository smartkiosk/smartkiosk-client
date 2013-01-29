class CreatePhoneRanges < ActiveRecord::Migration
  def change
    create_table :phone_ranges do |t|
      t.decimal  :start # it`s decimal because mysql do magic for integer
      t.decimal  :end
      t.belongs_to :provider

      t.timestamps
    end
    add_index :phone_ranges, :start
    add_index :phone_ranges, :end
    add_index :phone_ranges, :provider_id
  end
end