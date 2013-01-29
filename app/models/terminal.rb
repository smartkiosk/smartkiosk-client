require 'smartware'
require 'socket'
require 'redis'
require 'redis/objects'

Application.load 'lib/smartkiosk/config/yaml'

class Terminal
  include Redis::Objects

  value :state, :global => true
  value :started_at, :global => true, :marshal => true
  value :modified_at, :global => true, :marshal => true
  value :payment_in_progress, :global => true

  value :support_phone, :global => true
  value :providers_updates, :global => true, :marshal => true

  def self.smartguard
    DRbObject.new_with_uri(Terminal.config.smartguard_host)
  end

  #
  # STATES
  #
  def self.enable
    self.state = 'active'
  end

  def self.disable
    self.state = 'disabled'
  end

  def self.payment_in_progress?
    self.payment_in_progress.value == "true"
  end

  def self.actual_state
    self.state.value || 'active'
  end

  def self.actual_modified_at
    self.modified_at.value || DateTime.now
  end

  def self.providers_updated_at
    self.providers_updates[self.config.host] rescue nil
  end

  def self.providers_updated_at=(value)
    self.providers_updates = {self.config.host => value}
  end

  #
  # ACTIONS
  #
  def self.ping
    PingWorker.perform_async
  end

  def self.reload
    smartguard.restart_async
  end

  def self.reboot
    self.state = 'rebooting'
    StartupWorker.perform_async self.name, :enable

    smartguard.reboot_async
  end

  #
  # CONDITON
  #
  def self.config
    @config ||= Smartkiosk::Config::YAML.new(Application.root.join 'config/services/application.yml')
  end

  def self.keyword
    config.keyword
  end

  def self.enabled?
    self.actual_state == 'active'
  end

  def self.version
    '0.1'
  end

  def self.ip
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true

    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end
  rescue
    '0.0.0.0'
  ensure
    Socket.do_not_reverse_lookup = orig
  end

  def self.as_json
    {
      :started_at => Terminal.started_at.value,
      :modified_at => Terminal.actual_modified_at,
      :keyword => Terminal.keyword,
      :support_phone => Terminal.support_phone.value,
      :groups => Group.all.map{|x| x.as_json},
      :providers => Provider.active.map{|x| x.as_json},
      :promotions => Promotion.order(:priority).limit(6).map{|x| x.provider_id}
    }
  end

  def self.condition
    {
      :ip => ip,
      :state => Terminal.actual_state,
      :banknotes => Payment.merge_banknotes(Payment.uncollected),
      :cash => Payment.merge_cash(Payment.uncollected),
      :providers => {
        :updated_at => Terminal.providers_updated_at,
        :ids => Provider.select(:foreign_id).map{|x| x.foreign_id} || []
      },
      :queues => {
        :payments => Sidekiq::Queue.new('payments').size,
        :pings => Sidekiq::Queue.new('pings').size,
        :orders => Sidekiq::Queue.new('orders').size,
        :sync => Sidekiq::Queue.new('sync').size
      },
      :cash_acceptor => {
        :error => Smartware.cash_acceptor.error,
        :model => Smartware.cash_acceptor.model,
        :version => Smartware.cash_acceptor.version
      },
      :printer => {
        :error => Smartware.printer.error,
        :model => Smartware.printer.model,
       :version => Smartware.printer.version
      },
      :modem => {
        :error => Smartware.modem.error,
        :signal_level => Smartware.modem.signal_level,
        :balance => Smartware.modem.balance,
        :model => Smartware.modem.model,
        :version => Smartware.modem.version
      },
      :version => Terminal.version
    }
  end
end
