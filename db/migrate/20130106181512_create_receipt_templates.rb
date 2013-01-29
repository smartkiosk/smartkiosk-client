class CreateReceiptTemplates < ActiveRecord::Migration
  def change
    create_table :receipt_templates do |t|
      t.string :keyword
      t.text :template
      t.timestamps
    end
  end
end
