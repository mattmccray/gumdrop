require 'logger'

module Gumdrop  
  
  module Util
    module Loggable
      def log
        Gumdrop.log
      end
    end
  end

  class << self

    LOG_LEVELS= {
        debug: Logger::DEBUG,
         info: Logger::INFO,
         warn: Logger::WARN,
        error: Logger::ERROR,
        fatal: Logger::FATAL,
      unknown: Logger::UNKNOWN
    }

    def log
      @log ||= begin
        log= Logger.new STDOUT
        log.level= LOG_LEVELS[:warn]
        log
      end
    end

    def init_logging
      level= (site.config.log_level || :warn).to_sym
      @log = Logger.new site.config.log
      @log.level=  LOG_LEVELS[level]
    end

  end

end