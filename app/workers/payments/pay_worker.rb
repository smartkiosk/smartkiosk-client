require 'rest-client'

module Payments
  class PayWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :payments

    def perform(payment_id)
      payment = Payment.find(payment_id)
      response = RestClient.post "#{Terminal.config.host}/payments/#{payment.foreign_id}/pay",
                                 :provider => payment.provider.keyword,
                                 :terminal => Terminal.config.keyword,
                                 :payment => {
                                    :paid_amount => payment.paid_amount,
                                    :card_track1 => payment.card_track1,
                                    :card_track2 => payment.card_track2
                                  }
      Sidekiq::Logging.logger.debug "Pay response: #{response.to_s}"
      payment.update_attributes(
        :processed => true,
        :card_track1 => nil,
        :card_track2 => nil
      ) if response
    end
  end
end