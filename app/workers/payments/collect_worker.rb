Application.load 'lib/smartkiosk/sidekiq'

module Payments
  class CollectWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :payments

    def perform(collection_id)
      collection = Collection.find(collection_id)

      response = RestClient.post "#{Terminal.config.host}/collections",
        :terminal => Terminal.config.keyword,
        :collection => {
          :banknotes => collection.banknotes,
          :collected_at => collection.created_at,
          :session_ids => collection.payment_ids
        }

      collection.update_attribute(:reported_at, DateTime.now)
    end
  end
end