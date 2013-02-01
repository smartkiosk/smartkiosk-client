require 'sidekiq'

module Sidekiq
  module Logging

    class Pretty < Logger::Formatter
      def call(severity, time, progname, msg)
        msg = "(TID-#{Thread.current.object_id.to_s(36)}#{context}) #{msg}"
        Smartkiosk::Common::Logging.format "Sidekiq", severity, time, progname, msg
      end
    end
  end
end