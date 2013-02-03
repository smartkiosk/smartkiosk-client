task :schedule do
  require 'rufus-scheduler'
  scheduler = Rufus::Scheduler.start_new

  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  logger.formatter = proc do |severity, time, progname, msg|
    Smartkiosk::Common::Logging.format "Scheduler", severity, time, progname, msg
  end

  scheduler.every '1m' do
    logger.debug "Terminal ping"
    Terminal.ping
  end

  scheduler.every '3h', :first_in => '1s' do
    logger.debug "Receipt Templates sync"
    Sync::ReceiptTemplatesWorker.perform_async
  end

  logger.debug "Schedule loaded"
  begin 
    scheduler.join
  rescue Interrupt
    logger.debug "Interrupting..."
  end
end