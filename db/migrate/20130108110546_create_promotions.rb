class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.belongs_to    :provider
      t.integer       :priority
      t.timestamps
    end
  end
end
