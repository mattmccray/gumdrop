module Gumdrop

  class CLI
    
    def initialize(out)
      @out = out
    end
    
    def run(args)
      puts "I don't do anything yet. Soon I'll let you create, build, export, or serve a gumdrop project. (v#{Gumdrop::VERSION})"
    end
    
    class << self

      def run(args, out=STDOUT)
        self.new(out).run(args)
      end
      
    end
  end

end