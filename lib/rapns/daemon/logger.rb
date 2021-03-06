module Rapns
  module Daemon
    class Logger
      def initialize(options)
        @options = options
        log_path = File.join(Rails.root, 'log', 'rapns.log')
        @logger = ActiveSupport::BufferedLogger.new(log_path, Rails.logger.level)
        @logger.auto_flushing = Rails.logger.respond_to?(:auto_flushing) ? Rails.logger.auto_flushing : true
      end

      def info(msg)
        log(:info, msg)
      end

      def error(err, options = {})
        airbrake_notify(err) if notify_via_airbrake?(err, options)
        if err.class.ancestors.include?(Exception)
          msg = "#{err.message}"
          msg += "\n#{err.backtrace.join("\n")}" unless err.backtrace.blank?
        else
          msg = err
        end
        log(:error, err, 'ERROR')
      end

      def warn(msg)
        log(:warn, msg, 'WARNING')
      end

      private

      def log(where, msg, prefix = nil)
        if msg.is_a?(Exception)
          msg = "#{msg.class.name}, #{msg.message}"
        end

        formatted_msg = "[#{Time.now.to_s(:db)}] "
        formatted_msg << "[#{prefix}] " if prefix
        formatted_msg << msg
        puts formatted_msg if @options[:foreground]
        @logger.send(where, formatted_msg)
      end

      def airbrake_notify(e)
        return unless @options[:airbrake_notify] == true

        if defined?(Airbrake)
          Airbrake.notify(e)
        elsif defined?(HoptoadNotifier)
          HoptoadNotifier.notify(e)
        end
      end

      def notify_via_airbrake?(msg, options)
        msg.is_a?(Exception) && options[:airbrake_notify] != false
      end
    end
  end
end
