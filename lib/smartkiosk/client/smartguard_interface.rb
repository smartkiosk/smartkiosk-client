module Smartkiosk
  class Client
    class SmartguardInterface

      @@instance = nil

      def self.instance
        if @@instance.nil?
          @@instance = self.new
        end

        @@instance
      end

      def initialize
        @@instance = self

        if !EventMachine.reactor_running?
          @queue = Queue.new
          Thread.new &method(:thread)
          @queue.pop
          @queue = nil
        end

        if AMQP.current.nil?
          connection = AMQP.connect
          @channel   = AMQP::Channel.new connection
        else
          @channel = AMQP.current
        end


        @guard_commands  = @channel.fanout "smartguard.commands", auto_delete: true
        @guard_status    = @channel.topic "smartguard.events", durable: true
      end

      def post_order(id, *args)
        EventMachine.schedule do
          @guard_commands.publish JSON.dump({
            id: "order.#{id}",
            command: args
          })
        end
      end

      def read_order_completion(&block)
        queue = @channel.queue "smartkiosk-client.smartguard-events", durable: true
        queue.bind @guard_status, routing_key: "command.order.#"
        queue.subscribe do |header, message|
          key = header.routing_key.split '.'
          if key[3] == "finished"
            yield key[2].to_i
          end
        end
      end

      private

      def thread
        EventMachine.run do
          @queue.push nil
        end
      end
    end
  end
end
