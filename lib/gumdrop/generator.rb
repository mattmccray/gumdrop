module Gumdrop

  class Generator
    attr_reader :filename, :base_path, :params, :pages
    
    def initialize(content, opts={})
      @content= content
      if @content.is_a? Proc
        @filename= ""
        @base_path= ""
      else
        @filename= content.filename || ""
        @base_path= content.slug || ""
      end
      @params= HashObject.new
      @pages= []
    end
    
    def execute
      if @content.is_a? Proc
        run_dsl_from_proc @content
      else
        run_dsl_from_source IO.readlines(@content.path).join('')
      end
    end
    
    def data
      Gumdrop.data
    end
    
    def set(var_name, value)
      params[var_name]= value
    end
    
    def page(name, opts={}, &block)
      name= name[1..-1] if name.starts_with?('/')
      opts= params.reverse_merge(opts)
      filepath= if @base_path.empty?
        "/#{name}"
      else
        "/#{@base_path}/#{name}"
      end
      content= GeneratedContent.new(filepath, opts)
      content.template = if Gumdrop.layouts.has_key?( opts[:template] )
        Gumdrop.layouts[ opts[:template] ]
      else
        Gumdrop.layouts[ "#{opts[:template]}.template" ]
      end.template
      
      Gumdrop.site[content.uri]= content
    end
    
    def run_dsl_from_source(source)
      # puts source
      instance_eval source
    end

    def run_dsl_from_proc(proc)
      # puts source
      instance_eval &proc
    end
    
  end
  
  class GeneratedContent < Content
    # Nothing special, per se...
  end
  
end