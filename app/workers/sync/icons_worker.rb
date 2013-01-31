require 'rest-client'

module Sync
  class IconsWorker
    include Sidekiq::Worker

    sidekiq_options :retry => false, :queue => :sync

    def perform(model, id, url)
      entity  = model.constantize.find(id)
      attempt = entity.update_attributes :remote_icon_url => "#{Terminal.config.host}/#{url}"

      unless attempt
        Sync::IconsWorker.perform_in(1.minute, model, id, url)
      end
    end
  end
end