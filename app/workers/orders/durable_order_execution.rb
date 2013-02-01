module Orders
  module DurableOrderExecution
    def safely_execute_order(order_id, &block)
      pid = Process.fork
      return unless pid.nil?

      Process.setsid

      begin
        Smartkiosk::Client::Logging.logger.debug "Started execution of order #{order_id}"
        yield
        Smartkiosk::Client::Logging.logger.debug "Completed execution of order #{order_id}"

      rescue => e
        Smartkiosk::Client::Logging.logger.debug "Execution of order #{order_id} failed: #{e}"

        begin
          AcknowledgeWorker.perform_async order_id, e.to_s
        rescue => ne
          Smartkiosk::Client::Logging.logger.debug "Unable to schedule AcknowlegeWorker #{ne}"
          sleep 1
          retry
        end
      end

      begin
        CompleteWorker.perform_async order_id
      rescue => ne
        Smartkiosk::Client::Logging.logger.debug "Unable to schedule CompleteWorker: #{ne}"
        sleep 1
        retry
      end

      begin
        ActiveRecord::Base.connection.reconnect!

        Order.find(order_id).update_attribute(:complete, true)
      rescue => ne
        Smartkiosk::Client::Logging.logger.debug "Unable to mark completion: #{ne}"
        sleep 1
        retry
      end

      Process.exit!
    end
  end
end
