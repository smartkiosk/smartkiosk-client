require 'sidekiq'

Application.load 'lib/sidekiq'

module Orders
  class RebootWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :orders

    def perform(order_id)
      StartupWorker.perform_async self.class.name, :finish, [order_id]
      Terminal.reboot
    end

    def self.finish(order_id)
      Order.find(order_id).complete
    end
  end
end