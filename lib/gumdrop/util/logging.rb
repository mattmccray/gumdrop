require 'active_support/buffered_logger'

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
        debug:0,
         info:1,
         warn:2,
        error:3,
        fatal:4,
      unknown:5,
    }

    def log
      @log ||= ActiveSupport::BufferedLogger.new STDOUT, LOG_LEVELS[:warn]
    end

    def init_logging
      level= (site.config.log_level || :warn).to_sym
      @log = ActiveSupport::BufferedLogger.new site.config.log, LOG_LEVELS[level]
    end

  end

end