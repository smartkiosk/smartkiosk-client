class Promotion < ActiveRecord::Base
  belongs_to :provider

  after_save do
    Terminal.modified_at = DateTime.now
  end

  after_destroy do
    Terminal.modified_at = DateTime.now
  end
end
