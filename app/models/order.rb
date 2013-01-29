class Order < ActiveRecord::Base

  serialize :args
  #
  # METHODS
  #
  def acknowledge
    Orders::AcknowledgeWorker.perform_async id
  end

  def acknowledged!
    update_attribute(:acknowledged, true)
  end

  def complete
    return if complete?

    update_attribute(:complete, true)
    Orders::CompleteWorker.perform_async id
  end

  def perform
    "orders/#{keyword}_worker".camelize.constantize.perform_async(id)
  end
end