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

    def self.view_helpers(&block)
      Gumdrop::ViewHelpers.class_eval &block
    end

    def self.configure(&block)
      Gumdrop::Configurator.instance_eval &block
    end
  
  end
end