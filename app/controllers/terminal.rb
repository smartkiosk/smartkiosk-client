require 'uri'

Application.load 'lib/pinger'

class Application
  get '/terminal' do
    json Terminal
  end

  get '/front_error' do
    logger.warn "#{params['url']}@#{params['line']}: #{params['message']}"
  end

  get '/terminal/condition' do
    json Terminal.condition.merge(:keyword => Terminal.keyword)
  end

  get '/terminal/logs' do
    files = {
      :smartguard => '/var/log/smartguard.log',
      :front => Application.root.join('log/web.log'),
      :sidekiq => Application.root.join('log/sidekiq.log'),
      :smartware => Application.root.join('log/smartware.log')
    }

    files.keys.each do |entry|
      path = files[entry]
      files[entry] = []

      next unless File.exist? path

      File::Tail::Logfile.tail(path, :backward => 1000, :return_if_eof => true) do |line|
        files[entry] << line
      end
    end

    json files
  end

  post '/terminal/enable' do
    Terminal.enable
    json(:state => Terminal.state)
  end

  post '/terminal/disable' do
    Terminal.disable
    json(:state => Terminal.state)
  end

  post '/terminal/reload' do
    Terminal.reload
    json(:state => Terminal.state)
  end

  post '/terminal/reboot' do
    Terminal.reboot
    json(:state => Terminal.state)
  end

  post '/terminal/recalibrate' do
    Terminal.recalibrate
  end

  get '/terminal/test_connection' do
    begin
      uri = URI.parse(Terminal.config.host)

      json(
        :server_http => Pinger.http(Terminal.config.host),
        :server_ping => Pinger.external(uri.host),
        :google_ping => Pinger.external('google.com')
      )
    rescue
      json {}
    end
  end

  get '/terminal/test_printer' do
    Smartware.printer.test
    nil
  end

  get '/terminal/print_balance' do
    period_start   = Collection.order('created_at DESC').first.try(:created_at)
    period_start ||= Payment.order(:created_at).first.try(:created_at)
    period_start ||= Date.civil(0, 1, 1)

    receipt = Receipt.create :template => ReceiptTemplate.read('balance'),
                              :keyword => 'balance',
                              :fields   => {
                                  :balance      => Payment.merge_cash,
                                  :period_start => I18n.l(period_start),
                                  :period_end   => I18n.l(Time.now)
                              }

    receipt.print
    nil
  end
end