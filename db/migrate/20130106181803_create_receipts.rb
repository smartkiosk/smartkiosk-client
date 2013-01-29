class CreateReceipts < ActiveRecord::Migration
  def change
    create_table :receipts do |t|
      t.text    :fields
      t.text    :template
      t.string  :keyword
      t.boolean :printed, :default => false
      t.integer :document_id
      t.string  :document_type

      t.timestamps
    end
    add_index :receipts, [:document_id, :document_type]
  end
end