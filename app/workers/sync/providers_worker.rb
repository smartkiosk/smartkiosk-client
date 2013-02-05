require 'rest-client'

module Sync
  class ProvidersWorker
    include Sidekiq::Worker

    sidekiq_options :retry => false, :queue => :sync

    SEMAPHORE = ConnectionPool.new(:size => 1, :timeout => 5) { true }

    def perform
      SEMAPHORE.with do |glory|

        syncs = []

        Sidekiq::Logging.logger.info "Requesting providers"

        begin
          providers = RestClient::Request.execute(
            :method       => :get,
            :url          => "#{Terminal.config.host}/terminal_pings/providers",
            :timeout      => 40,
            :open_timeout => 60,
            :headers      => {
              :params     => {
                :terminal => Terminal.keyword
              }
            }
          )
        rescue Exception => e
          Sidekiq::Logging.logger.warn e.to_s
          return
        end

        begin
          providers = JSON.parse(ActiveSupport::Gzip.decompress(providers.to_s), :symbolize_names => true)
        rescue Exception => e
          Sidekiq::Logging.logger.warn "Unable to parse providers JSON: #{e.to_s}"
          return
        end

        return if !Terminal.providers_updated_at.nil? && Terminal.providers_updated_at >= providers[:updated_at]

        ActiveRecord::Base.transaction do
          Promotion.destroy_all
          Provider.destroy_all
          Group.destroy_all

          providers[:groups].each do |r|
            local = Group.new
            local.id = r[:id]
            local.title = r[:title]
            local.priority = r[:priority]
            local.group_id = r[:parent_id]
            local.save!

            unless r[:icon].blank?
              syncs << ['Group', local.id, r[:icon]]
            end
          end

          providers[:providers].each do |r|
            icon = r.delete :icon

            local = Provider.new
            local.id = r.delete :id
            local.attributes = r
            local.save!

            unless icon.blank?
              syncs << ['Provider', local.id, icon]
            end
          end

          providers[:promotions].each_with_index do |r, i|
            Promotion.create(
              :provider_id => r,
              :priority => i
            )
          end
        end

        Terminal.providers_updated_at = providers[:updated_at]
        Sidekiq::Logging.logger.info "Providers updated. Timestamp: #{providers[:updated_at]}"
        Sidekiq::Logging.logger.info "Icons to sync: #{syncs}"

        syncs.each do |args|
          Sync::IconsWorker.perform_async *args
        end
      end
    rescue Timeout::Error => e
      Sidekiq::Logging.logger.warn "Semaphore timeout. #{e.to_s}"
    end
  end
end
