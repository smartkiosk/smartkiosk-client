require 'rest-client'

class PingWorker
  include Sidekiq::Worker

  sidekiq_options :retry => false, :queue => :pings

  SEMAPHORE = ConnectionPool.new(:size => 1, :timeout => 5) { true }

  def perform
    begin
      SEMAPHORE.with do |glory|
        condition = Terminal.condition

        Sidekiq::Logging.logger.info "Requesting with updated_at: #{Terminal.providers_updated_at}"

        begin
          response = RestClient::Request.execute(
            :method       => :post,
            :url          => "#{Terminal.config.host}/terminal_pings",
            :timeout      => 40,
            :open_timeout => 60,
            :payload      => {
              :terminal => Terminal.keyword,
              :terminal_ping => condition
            }
          )
        rescue Exception => e
          Sidekiq::Logging.logger.warn e.to_s
          return
        end

        begin
          response = JSON.parse(response.to_s, :symbolize_names => true)
        rescue Exception => e
          Sidekiq::Logging.logger.warn "Unable to parse JSON: #{e.to_s}"
          return
        end

        Sidekiq::Logging.logger.info "Response: #{response.inspect}"

        #
        # PROFILE
        #
        unless Terminal.modified_at == response[:profile][:modified_at]
          Terminal.support_phone = response[:profile][:support_phone]
          Terminal.modified_at = response[:profile][:modified_at]
          Sync::LogoWorker.perform_async response[:profile][:logo]
        end

        #
        # ORDERS
        #
        response[:orders].each do |foreign|
          existing = Order.find_by_foreign_id(foreign[:id])

          unless existing.nil?
            if existing.foreign_created_at == foreign[:created_at] || # same order, not yet acknowleged
               !existing.complete?                                    # not completed yet
                next
            end

            existing.destroy
          end

          foreign[:foreign_id] = foreign.delete(:id)
          foreign[:foreign_created_at] = foreign.delete(:created_at)
          order = Order.create!(foreign)

          order.acknowledge
          order.perform
        end

        Sync::ProvidersWorker.perform_async if response[:update_providers]
      end
    rescue Timeout::Error => e
      Sidekiq::Logging.logger.warn "Semaphore timeout. #{e.to_s}"
    end
  end
end