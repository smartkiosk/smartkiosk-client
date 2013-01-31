module Orders
  class DisableWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :orders

    def perform(order_id)
      order = Order.find(order_id)

      Terminal.disable
      order.complete
    end
  end
end