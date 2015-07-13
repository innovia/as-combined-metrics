require 'logger'

module AsCombinedMetrics::Cli::Logging
  def logger
    @logger ||= AsCombinedMetrics::Cli::Logging.logger_for(self.class.name, options[:log_level])
  end

  # Use a hash class-ivar to cache a unique Logger per class:
	@loggers = {}
		
  class << self 
    def logger_for(class_name, level)
      @loggers[class_name] ||= configure_logger_for(level)
    end

    def configure_logger_for(level)
      logger = Logger.new(STDOUT)
      logger.level = Object.const_get("Logger::#{level.upcase}")
      logger
    end
  end
end


