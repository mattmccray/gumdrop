module Gumdrop
  module DSL
  
    def self.generate(&block)
      # Auto-generated, numerical, key for a site-level generator
      Gumdrop.generators[Gumdrop.generators.keys.length] = Generator.new(block)
    end
  
    def self.content_filter(&block)
      Gumdrop.content_filters << block
    end
  
    def self.skip(path)
      Gumdrop.report " blacklist: #{path}", :info
      Gumdrop.blacklist << path
    end

    def self.ignore(path)
      Gumdrop.report "  greylist: #{path}", :info
      Gumdrop.greylist << path
    end
  
  end
end