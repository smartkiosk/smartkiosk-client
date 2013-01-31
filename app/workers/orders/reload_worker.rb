module Orders
  class ReloadWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :orders

    def perform(order_id)
      Smartkiosk::Client::SmartguardInterface.instance.post_order order_id, "restart"
    end
  end
end