require 'rest-client'

Application.load 'lib/smartkiosk/sidekiq'

module Sync
  class ReceiptTemplatesWorker
    include Sidekiq::Worker

    sidekiq_options :retry => false, :queue => :sync

    def perform
      params = {
        :terminal => Terminal.config.keyword
      }

      response  = RestClient.get "#{Terminal.config.host}/system_receipt_templates?#{params.to_query}"
      templates = JSON.parse(response.to_s, :symbolize_names => true)

      templates.each do |entry|
        ReceiptTemplate.find_or_create_by_keyword(entry[:keyword]).
          update_attributes :template => entry[:template]
      end

      nil
    end
  end
end