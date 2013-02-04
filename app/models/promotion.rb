class Promotion < ActiveRecord::Base
  belongs_to :provider

  scope :active, lambda{
    scoped.includes(:provider).where(Provider.arel_table[:fields_count].gt 0)
  }

  after_save do
    Terminal.modified_at = DateTime.now
  end

  after_destroy do
    Terminal.modified_at = DateTime.now
  end
end
