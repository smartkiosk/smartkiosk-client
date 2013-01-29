require 'sidekiq'
require 'rest-client'

Application.load 'lib/sidekiq'

module Payments
  class PayWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :payments

    def perform(payment_id)
      payment = Payment.find(payment_id)
      response = RestClient.post "#{Terminal.config.host}/payments/#{payment.foreign_id}/pay",
                                 :provider => payment.provider.keyword,
                                 :terminal => Terminal.config.keyword,
                                 :payment => { :paid_amount => payment.paid_amount }
      Sidekiq::Logging.logger.debug "Pay response: #{response.to_s}"
      payment.update_attributes(:processed => true) if response
    end
  end
end