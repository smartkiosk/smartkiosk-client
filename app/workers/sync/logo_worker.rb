require 'rest-client'

module Sync
  class LogoWorker
    include Sidekiq::Worker

    sidekiq_options :retry => true, :queue => :sync

    def perform(url)
      if url.nil?
        Terminal.logo_url = nil
      else
        uploader = IconUploader.new
        uploader.download! "#{Terminal.config.host}/#{url}"
        Terminal.logo_url = uploader.url
      end
    end
  end
end
