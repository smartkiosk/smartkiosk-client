require 'rest-client'

class PingWorker
  include Sidekiq::Worker

  sidekiq_options :retry => false, :queue => :pings

  DAY = 24 * 3600
  SEMAPHORE = ConnectionPool.new(:size => 1, :timeout => 5) { true }

  def perform
    begin
      SEMAPHORE.with do |glory|
        condition = Terminal.condition

        Sidekiq::Logging.logger.info "Requesting with updated_at: #{Terminal.providers_updated_at}"

        sessions_per_day = {}
        sessions = SessionRecord.all

        sessions.each do |session|
          next if session.time == 0

          session_start = session.started_at
          session_start -= session_start % DAY
          session_end = session.started_at + session.time

          session_start.step(session_end - 1, DAY) do |day|
            day_time = [ day + DAY - 1, session.started_at + session.time ].min -
                       [ day, session.started_at ].max

            fraction = day_time / session.time

            sessions_per_day[day] = {
              upstream:   session.upstream * fraction,
              downstream: session.downstream * fraction,
              time:       session.time * fraction
            }
          end
        end

        sessions.each do |day, charges|
          Sidekiq::Logging.logger.info "reporting #{charges.inspect} on #{day}"
        end

        begin
          response = RestClient::Request.execute(
            :method       => :post,
            :url          => "#{Terminal.config.host}/terminal_pings",
            :timeout      => 40,
            :open_timeout => 60,
            :headers => {
              "Content-Type" => "application/json",
              "Accept"       => "application/json"
            },
            :payload => JSON.dump(
              :terminal => Terminal.keyword,
              :terminal_ping => condition,
              :sessions => sessions_per_day
            )
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

        ActiveRecord::Base.transaction do
          sessions.each &:destroy
        end

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