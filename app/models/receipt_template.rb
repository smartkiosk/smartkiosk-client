class ReceiptTemplate < ActiveRecord::Base
  def self.read(keyword)
    find_by_keyword(keyword).try(:template) || "!!! Template not found !!!"
  end
end
