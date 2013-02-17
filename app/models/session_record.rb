class SessionRecord < ActiveRecord::Base
  scope :recent, where(
    arel_table[:created_at].gt(Date.today-1.month)
  ).order(arel_table[:id].desc)
end
