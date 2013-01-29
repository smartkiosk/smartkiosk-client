require 'uri'

Application.load 'lib/pinger'

class Application
  get '/terminal' do
    Terminal.payment_in_progress = params[:payment_in_progress] == 'true'

    result = {
      :enabled => Terminal.enabled?,
      :started_at => Terminal.started_at.value
    }

    modified_at = Terminal.actual_modified_at.change(:usec => 0)

    if params[:modified_at] && (modified_at > DateTime.parse(params[:modified_at]))
      result[:terminal] = Terminal.as_json
    end

    result.to_json
  end

  get '/terminal/condition' do
    Terminal.condition.merge(:keyword => Terminal.keyword).to_json
  end

  get '/terminal/logs' do
    files = {
      :smartguard => '/var/log/smartguard.log',
      :front => Rails.root.join('log/production.log'),
      :sidekiq => Rails.root.join('log/sidekiq.log'),
      :smartware => Rails.root.join('log/smartware.log')
    }

    files.keys.each do |entry|
      path = files[entry]
      files[entry] = []
      
      File.open(path) do |f|
        f.extend(File::Tail)
        f.backward(1000)
        1000.times{ files[entry] << f.readline } rescue nil
      end if File.exist?(path)
    end

    files.to_json
  end

  post '/terminal/enable' do
    Terminal.enable
    {:state => Terminal.actual_state}.to_json
  end

  post '/terminal/disable' do
    Terminal.disable
    {:state => Terminal.actual_state}.to_json
  end

  post '/terminal/reload' do
    Terminal.reload
    {:state => Terminal.actual_state}.to_json
  end

  post '/terminal/reboot' do
    Terminal.reboot
    {:state => Terminal.actual_state}.to_json
  end

  get '/terminal/test_connection' do
    begin
      uri = URI.parse(Terminal.config.host)

      {
        :server_http => Pinger.http(Terminal.config.host),
        :server_ping => Pinger.external(uri.host),
        :google_ping => Pinger.external('google.com')
      }.to_json
    rescue
      {}.to_json
    end
  end

  get '/terminal/test_printer' do
    Smartware.printer.test
    ""
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
    ""
  end
end