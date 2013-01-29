require 'carrierwave/orm/activerecord'

class Provider < ActiveRecord::Base
  belongs_to :group
  serialize :fields

  mount_uploader :icon, IconUploader

  scope :active, where(arel_table[:fields_count].gt 0)

  before_save do
    self.fields_count = fields.length
  end

  after_save do
    Terminal.modified_at = DateTime.now
  end

  after_destroy do
    Terminal.modified_at = DateTime.now
  end

  def as_json
    {
      :id => id,
      :group => group_id,
      :keyword => keyword,
      :title => title,
      :icon => icon.url,
      :fields => fields
    }
  end

  def self.to_hash(column, entries=false, options={})
    scope = Provider.select([:id, column])
    scope = scope.where(column => entries) if entries
    scope = scope.map{|x| [x.id, x.send(column)]} if options[:invert].blank?
    scope = scope.map{|x| [x.send(column), x.id]} if options[:invert]

    Hash[*scope.flatten]
  end
end
