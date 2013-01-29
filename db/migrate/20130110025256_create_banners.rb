class CreateBanners < ActiveRecord::Migration
  def change
    create_table :banners do |t|
      t.boolean   :visible, :default => false
      t.decimal   :duration
      t.integer   :playorder
      t.string    :filename

      t.timestamps
    end
  end
end