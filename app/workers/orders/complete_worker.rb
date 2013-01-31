require 'rest-client'

module Orders
  class CompleteWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :orders

    def perform(order_id)
      order = Order.find(order_id)

      response = RestClient.post "#{Terminal.config.host}/terminal_orders/#{order.foreign_id}/complete",
        :terminal => Terminal.keyword

      Terminal.ping
    end
  end
end