module Gumdrop::Util
  
  PARSER= /^(\s*---(.+)---\s*)/m

  class YamlDoc

    attr_reader :data, :body

    def initialize(source, extended=false)
      @data= {}
      @body= source
      @extended= extended
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
        @is_yamldoc= false
      end

      return unless @extended or !@is_yamldoc

      content_set= false
      @data.each_pair do |key, value|
        if value == '_YAMLDOC_'
          @data[key]= @content
          content_set= true
        end
      end
      @data['content']= @content unless content_set
    end

  end

end