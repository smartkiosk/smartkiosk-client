class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.belongs_to    :group
      t.string        :title
      t.string        :icon
      t.integer       :priority
      t.timestamps
    end
  end
end
