require 'carrierwave/orm/activerecord'

class Group < ActiveRecord::Base
  has_many :providers
  has_many :groups

  default_scope order(:priority)

  mount_uploader :icon, IconUploader

  after_save do
    Terminal.modified_at = DateTime.now
  end

  after_destroy do
    Terminal.modified_at = DateTime.now
  end

  def icon_url
    icon.url
  end

  def as_json
    {
      :id => id,
      :title => title,
      :icon => icon.url,
      :parent => group_id
    }
  end
end
