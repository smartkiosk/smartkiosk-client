require 'sidekiq'
require 'rest-client'

Application.load 'lib/sidekiq'

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

        unless Terminal.support_phone.value == response[:support_phone]
          Terminal.support_phone = response[:support_phone]
          Terminal.modified_at = DateTime.now
        end

        Sidekiq::Logging.logger.info "Response: #{response.inspect}"

        #
        # ORDERS
        #
        response[:orders].each do |order|
          next unless Order.find_by_foreign_id(order[:id]).blank?

          order[:foreign_id] = order.delete(:id)
          order = Order.create!(order)

          order.acknowledge
          order.perform
        end

        #
        # PROVIDERS
        #
        unless response[:providers].blank?
          syncs = []

          Provider.transaction do
            #
            # GROUPS
            #
            unless response[:providers][:groups].nil?
              remote     = response[:providers][:groups]
              remote_ids = response[:providers][:groups].map{|x| x[:id]}
              local      = Group.all

              local.select{|x| !remote_ids.include?(x.id)}.each do |x|
                Sidekiq::Logging.logger.info "Group removal: ##{x.id}, #{x.title}"
                x.destroy
              end

              remote.each do |r|
                entry   = local.find{|x| x.id == r[:id]}
                entry ||= Group.new :foreign_id => r[:id]

                entry.title = r[:title]
                entry.priority = r[:priority]
                entry.group_id = r[:parent_id]

                Sidekiq::Logging.logger.info "Group replace: #{entry.title}"

                entry.save!

                unless r[:icon].blank?
                  syncs << ['Group', entry.id, r[:icon]]
                end
              end
            end

            #
            # PROVIDERS REMOVAL
            #
            unless response[:providers][:remove].blank?
              Sidekiq::Logging.logger.info "Providers removal: #{response[:providers][:remove]}"
              Provider.where(:foreign_id => response[:providers][:remove]).destroy_all
            end

            #
            # PROVIDERS UPDATES
            #
            unless response[:providers][:updated_at].blank?
              response[:providers][:update].each do |provider|
                local = Provider.find_or_initialize_by_foreign_id(provider[:id])

                attributes = {
                  :title          => provider[:title],
                  :keyword        => provider[:keyword],
                  :priority       => provider[:priority],
                  :fields         => provider[:fields],
                  :group_id       => provider[:group_id],
                  :requires_print => provider[:requires_print]
                }

                if provider[:icon].blank?
                  attributes[:icon] = nil
                end

                local.assign_attributes attributes

                Sidekiq::Logging.logger.info "Provider replace: #{local.keyword}"

                local.save!

                unless provider[:icon].blank?
                  syncs << ['Provider', local.id, provider[:icon]]
                end
              end
            end

            #
            # PROMOTIONS
            #
            unless response[:providers][:promotions].nil?
              providers = Provider.to_hash(:foreign_id, response[:providers][:promotions], :invert => true)
              remote = response[:providers][:promotions].map{|x| providers[x]}.compact
              local  = Promotion.all

              local.select{|x| !remote.include?(x.provider_id)}.each do |x|
                Sidekiq::Logging.logger.info "Promotion removal: #{x.provider_id}"
                x.destroy
              end

              remote.each_with_index do |r, i|
                entry   = local.find{|x| x.provider_id == r}
                entry ||= Promotion.new :provider_id => r

                Sidekiq::Logging.logger.info "Promotion replace: #{r}"

                entry.priority = i
                entry.save!
              end
            end
          end

          unless response[:providers][:updated_at].blank?
            Terminal.providers_updated_at = response[:providers][:updated_at]
          end

          Sidekiq::Logging.logger.info "Icons to sync: #{syncs}"

          syncs.each do |args|
            Sync::IconsWorker.perform_async *args
          end
        end
      end
    rescue Timeout::Error => e
      Sidekiq::Logging.logger.warn "Semaphore timeout. #{e.to_s}"
    end
  end
end