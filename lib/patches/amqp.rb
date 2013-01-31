require 'amqp'
require 'bunny'

module AMQP
  class <<self
    attr_accessor :current

    def channel
      AMQP::Channel.new(AMQP.connect)
    end

    def send_isolated(queue, message, options={})
      Bunny.run do |client|
        client.with_channel do |channel|
          channel.default_exchange.publish message, 
            {
              :routing_key => queue,
              :persistent => false
            }.merge(options)
        end
      end
    end

    def send(queue, message, options={})
      return false unless AMQP.current
      AMQP.current.default_exchange.publish message,
        {
          :routing_key => queue,
          :persistent => false
        }.merge(options)
      true
    end
  end
end