class Payment < ActiveRecord::Base
  belongs_to :provider
  has_one :receipt, :as => :document, :dependent => :destroy

  default_scope includes(:provider)

  scope :complete, where(:processed => true)
  scope :uncollected, where(:collection_id => nil)

  serialize :fields
  serialize :limits
  serialize :commissions
  serialize :banknotes

  validates :provider, :presence => true

  before_save do
    if banknotes
      self.paid_amount = banknotes.inject(0){|sum, (nominal, count)| sum + nominal.to_i*count.to_i }
      self.commission_amount = commission_for(self.paid_amount)
    end
  end

  after_save do
    if checked?
      r = Receipt.find_or_create_by_document_id_and_document_type(id, self.class.name)
      r.update_attributes :template => self.receipt_template, 
        :keyword => 'payment',
        :fields => {
          :recipient => provider.title,
          :account => account,
          :payment_paid_amount => paid_amount || 0,
          :payment_enrolled_amount => ((paid_amount || 0) - (commission_amount || 0)).round(2),
          :payment_commission_amount => commission_amount || 0,
          :payment_paid_at => I18n.l(updated_at)
        }
    end
  end

  def self.merge_banknotes(payments=nil)
    payments ||= self.all
    payments.reject{|l| l.banknotes.nil? }.map(&:banknotes).reduce({}) do |result, entry|
      result.merge(entry) {|key, left, right| left.to_i+right.to_i }
    end
  end

  def self.merge_cash(payments=nil)
    payments ||= self.all
    payments.map(&:paid_amount).compact.sum
  end

  def title
    provider.title
  end

  def commission_for(amount)
    return 0 if commissions.blank?

    commission = commissions.select{|x| x.max >= amount && amount >= x.min }.
      sort_by{|x| x[:weight]}.first

    return 0 if commission.blank?

    static  = commission['static_fee'] || 0
    percent = ((commission['percent_fee'] || 0)/100*amount).round(2)

    static+percent
  end

  def check
    Payments::CheckWorker.new.perform(id)
    reload

    checked?
  end

  def pay
    Payments::PayWorker.perform_async(id)
  end
end