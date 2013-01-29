require 'liquid'

class Receipt < ActiveRecord::Base
  belongs_to :document, :polymorphic => true
  serialize :fields

  scope :recent, where(
    arel_table[:created_at].gt(Date.today-1.month).or(arel_table[:printed].eq(false))
  ).order(arel_table[:id].desc)

  def print
    data   = fields.merge(:id => id, :keyword => Terminal.config.keyword)
    result = Liquid::Template.parse(template).render data.with_indifferent_access
    update_attributes(:printed => true) if Smartware.printer.print_text(result)
  end

  def document_title
    document.blank? ? '' : document.title
  end

end