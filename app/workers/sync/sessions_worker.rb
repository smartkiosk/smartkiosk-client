require 'rest-client'

module Sync
  class SessionsWorker
    include Sidekiq::Worker

    sidekiq_options :retry => false, :queue => :sync

    def perform(from_time)
      sessions = SessionRecord.where("started_at > ?", from_time).order("started_at").all

      sessions.each do |session|
        Sidekiq::Logging.logger.info "- submitting session #{session.message_id}"

        providers = RestClient::Request.execute(
          :method       => :post,
          :url          => "#{Terminal.config.host}/session_records",
          :timeout      => 40,
          :open_timeout => 60,
          :payload => {
            :terminal => Terminal.keyword,
            :session_record => {
              :message_id => session.message_id,
              :started_at => session.started_at,
              :upstream   => session.upstream,
              :downstream => session.downstream,
              :time       => session.time
            }
          }
        )
      end

    rescue Exception => e
      Sidekiq::Logging.logger.warn e.to_s
    end
  end
end
