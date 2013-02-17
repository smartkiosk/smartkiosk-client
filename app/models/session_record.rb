class SessionRecord < ActiveRecord::Base
  scope :recent, order(arel_table[:id].desc).limit(100)
end
