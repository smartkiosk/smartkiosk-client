module Orders
  class EnableWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :orders

    def perform(order_id)
      order = Order.find(order_id)

      Terminal.enable
      order.complete
    end
  end
end