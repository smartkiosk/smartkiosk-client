class CreateProviders < ActiveRecord::Migration
  def change
    create_table :providers do |t|
      t.belongs_to  :group
      t.string      :keyword
      t.string      :title
      t.string      :icon
      t.integer     :priority
      t.text        :fields
      t.integer     :fields_count, :null => false, :default => 0
      t.boolean     :requires_print, :null => false, :default => false
      t.timestamps
    end
  end
end
