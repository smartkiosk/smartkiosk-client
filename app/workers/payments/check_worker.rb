require 'rest-client'

module Payments
  class CheckWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :payments

    def perform(payment_id)
      payment  = Payment.find(payment_id)
      response = RestClient.post "#{Terminal.config.host}/payments",
                  :provider => payment.provider.keyword,
                  :terminal => Terminal.config.keyword,
                  :payment  => {
                    :account => payment.account,
                    :payment_type => payment.payment_type,
                    :fields => payment.fields,
                    :session_id => payment.id
                  }

      Sidekiq::Logging.logger.debug "Check response: #{response.to_s}"

      answer = JSON.parse(response.to_s, :symbolize_names => true)

      unless answer[:id].nil?
        payment.update_attributes :foreign_id       => answer[:id],
                                  :limit            => answer[:limits].sort_by{|x| x[:weight]}.last,
                                  :commissions      => (answer[:commissions].empty? ? nil : answer[:commissions]),
                                  :receipt_template => answer[:receipt_template],
                                  :checked          => true
      end
    end
  end
end