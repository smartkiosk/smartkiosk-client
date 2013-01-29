require 'sidekiq'
require 'rest-client'

Application.load 'lib/sidekiq'

module Orders
  class AcknowledgeWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :orders

    def perform(order_id, error=nil, percent=nil)
      order = Order.find(order_id)

      response = RestClient.post "#{Terminal.config.host}/terminal_orders/#{order.foreign_id}/acknowledge",
        :terminal => Terminal.keyword,
        :error    => error,
        :percent  => percent

      order.acknowledged!
    end
  end
end