module Orders
  class ReloadWorker
    include Sidekiq::Worker
    include DurableOrderExecution

    sidekiq_options :queue => :orders

    def perform(order_id)
      safely_execute_order(order_id) do
        Smartguard::Client.restart
      end
    end
  end
end