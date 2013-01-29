Application.load 'lib/sidekiq'

class StartupWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :startup, :retry => false

  def perform(klass, method, args=[])
    klass.constantize.send method, *args
  end
end