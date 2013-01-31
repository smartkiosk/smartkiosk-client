module Orders
  class RebootWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :orders

    def perform(order_id)
      Smartkiosk::Client::SmartguardInterface.instance.post_order order_id, "reboot"
    end
  end
end