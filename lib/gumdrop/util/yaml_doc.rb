require 'yaml'

module Gumdrop::Util
  
  PARSER= /^(\s*---(.+)---\s*)/m

  class YamlDoc

    attr_reader :data, :body

    def initialize(source, extended_support=false)
      @data= {}
      @body= source
      @extended_support= extended_support
      _compile
    end

    def is_yamldoc?
      @is_yamldoc
    end
    
  private

    def _compile
      source = @body || ""

      if source =~ PARSER
        yaml = $2.strip
        @body = source.sub($1, '')
        @data= YAML.load(yaml)
        @is_yamldoc= true
      else
        @data={ 'content' => @body } if @extended_support
        @is_yamldoc= false
      end

      return unless @extended_support or !@is_yamldoc

      content_set= false
      @data.each_pair do |key, value|
        if value == '_YAMLDOC_'
          @data[key]= @body
          content_set= true
        end
      end
      @data['content']= @body unless content_set
    end

  end

end