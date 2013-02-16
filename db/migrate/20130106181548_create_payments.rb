class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.integer    :foreign_id
      t.belongs_to :provider
      t.belongs_to :collection
      t.string     :account
      t.string     :fields
      t.string     :banknotes
      t.string     :limit
      t.string     :commissions
      t.text       :receipt_template
      t.boolean    :error, :default => false
      t.boolean    :checked, :default => false
      t.boolean    :processed, :default => false
      t.boolean    :failed, :default => false
      t.text       :meta

      t.decimal    :paid_amount, :precision => 38, :scale => 2
      t.decimal    :commission_amount, :precision => 38, :scale => 2

      t.integer    :payment_type
      t.string     :card_track1
      t.string     :card_track2

      t.timestamps
    end

    add_index :payments, :provider_id
  end
end
