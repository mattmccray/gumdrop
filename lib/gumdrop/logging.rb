# Logging support

require 'logger'

module Gumdrop

  # def self.logger
  #   @log ||= Logger.new( 'log.txt', 'daily' )
  # end

  module Logging

    class << self

      def log
        Gumdrop.logger.info
      end

      def info

      end
      
      def warn

      end

      def error

      end

      def debug
      
      end
        
    end

  end

end
