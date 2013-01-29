class PhoneRange < ActiveRecord::Base
  scope :by_range, lambda {|query| where(PhoneRange.arel_table[:start].lteq(query.ljust(10, '0').to_i)).where(PhoneRange.arel_table[:end].gteq(query.ljust(10, '0').to_i)) }
end
