module Gumdrop

  class << self

    # Allows addition of CLI commands from Gumdrop file:
    #
    #  Gumdrop.cli do
    #    desc 'ping'
    #    method_option :loud, default:false
    #    def ping
    #      say options[:loud] ? 'PONG!' : 'pong'
    #    end
    #  end
    #
    def cli(&block)
      Gumdrop::CLI::Internal.class_eval &block
    end

    # Use this... To help make it clear that it's not a proc
    def cli_extend(&block)
    end

  end

end