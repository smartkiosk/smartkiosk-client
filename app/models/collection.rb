class Collection < ActiveRecord::Base
  has_one :receipt, :as => :document, :dependent => :destroy

  serialize :banknotes
  serialize :payment_ids

  after_save do
    period_start   = Collection.where("id != ?", self.id).order('created_at DESC').first.try(:created_at)
    period_start ||= Payment.order(:created_at).first.try(:created_at)
    period_start ||= Date.civil(0, 1, 1)

    r = Receipt.find_or_create_by_document_id_and_document_type(id, self.class.name)
    r.update_attributes :template => ReceiptTemplate.read('collection'), 
      :keyword => 'collection',
      :fields => {
        :period_start => I18n.l(period_start),
        :period_end   => I18n.l(created_at),
        :amount       => amount,
        :banknotes    => Hash[banknotes.sort].inject([]){|arr, (nom, cnt)| arr << {'nominal' => nom, 'count' => cnt, 'product' => nom.to_i*cnt.to_i} }
      }
  end

  def self.collect!
    payments = Payment.uncollected.complete.all

    return false if payments.blank?

    self.transaction do
      collection = self.create!(
        :banknotes => Payment.merge_banknotes(payments),
        :payment_ids => payments.map(&:id)
      )

      payments.each{|x| x.update_attribute :collection_id, collection.id}

      return collection
    end

    return false
  end

  def title
    amount
  end

  def report
    Payments::CollectWorker.perform_async(id)
  end

  def amount
    banknotes.inject(0){|sum, (nominal, count)| sum + nominal.to_i*count.to_i }
  end
end
