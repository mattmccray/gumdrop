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
      content= GeneratedContent.new(filepath, block, opts)
      if opts.has_key? :template and !opts[:template].nil?
        content.template = if Gumdrop.layouts.has_key?( opts[:template] )
          Gumdrop.layouts[ opts[:template] ]
        else
          Gumdrop.layouts[ "#{opts[:template]}.template" ]
        end.template
      end
      
      Gumdrop.site[content.uri]= content
    end
    
    def stitch(name, opts)
      require 'gumdrop/stitch_ex'
      page name do
        content= Stitch::Package.new(opts).compile
        if opts[:compress]
          require 'jsmin'
          JSMin.minify content
        else
          content
        end
      end
      if opts[:prune] and opts[:root]
        sp = File.expand_path('./source')
        rp = File.expand_path(opts[:root])
        relative_root = rp.gsub(sp, '')[1..-1]
        rrlen= relative_root.length - 1
        Gumdrop.site.keys.each do |path|
          if path[0..rrlen] == relative_root and name != path
            Gumdrop.site.delete path
          end
        end
      end
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

    def initialize(path, block, params={})
      @content_block= block
      super(path, params)
    end

    def render(ignore_layout=false,  reset_context=true, locals={})
      if @content_block.nil?
        super(ignore_layout, reset_context, locals)
      else
        @content_block.call
      end
    end

    def useLayout?
      !@content_block.nil? or !@template.nil?
    end

  end
  
end
