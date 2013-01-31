require 'smartkiosk/common'

module Smartkiosk
  class Client
    module Logging extend Smartkiosk::Common::Logging
      self.service = 'Web'

      class Middleware
        def initialize(app)
          @app = app
        end

        def call(env)
          began_at = Time.now
          status, header, body = @app.call(env)
          header = Rack::Utils::HeaderHash.new(header)
          log(env, status, header, began_at)
          [status, header, body]
        end

        def log(env, status, header, began_at)
          now = Time.now
          length = extract_content_length(header)

          Smartkiosk::Client::Logging.logger.info "#{status.to_s[0..3]} #{env["REQUEST_METHOD"]} " <<
            "#{env["PATH_INFO"]}#{env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"]}, " <<
            "#{length} (#{now - began_at})"

        end

        def extract_content_length(headers)
          value = headers['Content-Length'] or return '-'
          value.to_s == '0' ? '-' : value
        end
      end
    end
  end
end