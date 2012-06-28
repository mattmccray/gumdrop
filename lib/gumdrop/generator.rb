module Gumdrop

  class Generator

    include Support::Stitch
    include Support::Sprockets


    attr_reader :filename, :base_path, :params, :pages
    
    def initialize(content, site, opts={})
      @site= site
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
    
    # This should probably not be accessible to the generators
    def execute
      if @content.is_a? Proc
        instance_eval &@content
      else
        instance_eval File.read(@content.path)
      end
    end

    def site
      @site
    end
    
    def data
      @site.data
    end

    def config
      @site.config
    end
    
    def set(var_name, value)
      params[var_name]= value
    end

    def unload
      @pages.each do |content|
        @site.content_hash.delete content.uri
      end
    end
    
    def page(name, opts={}, &block)
      name= name[1..-1] if name.starts_with?('/')
      opts= params.reverse_merge(opts)
      filepath= if @base_path.empty?
        File.join @site.src_path, name
      else
        File.join @site.src_path, @base_path, @name
      end
      content= GeneratedContent.new(filepath, block, @site, self, opts)
      if opts.has_key? :template and !opts[:template].nil?
        content.template = if @site.layouts.has_key?( opts[:template] )
          @site.layouts[ opts[:template] ]
        else
          @site.layouts[ "#{opts[:template]}.template" ]
        end.template
      end
      content.ignore site.greylist.any? {|pattern| site.path_match name, pattern }
      unless content.ignored
        content.ignore site.blacklist.any? {|pattern| site.path_match name, pattern }
      end      
      @site.report " generated: #{content.uri}", :info
      @site.content_hash[content.uri]= content
      @pages << content
      content
    end

    # FIXME: Does redirect require abs-paths?
    def redirect(from, opts={})
      if opts[:to]
        page from do
          <<-EOF
          <meta http-equiv="refresh" content="0;url=#{ opts[:to] }">
          <script> window.location.href='#{ opts[:to] }'; </script>
          EOF
        end
        opts[:from]= from
        @site.redirects << opts
      else
        @site.report "You must specify :to in a redirect", :warning
      end
    end
    
  end
  
  class GeneratedContent < Content
    # Nothing special, per se...

    def initialize(path, block, site, generator, params={})
      super(path, site, params)
      @content_block= block
      @generated= true
      @generator= generator
    end

    def render(context=nil, ignore_layout=false,  reset_context=true, locals={})
      if @content_block.nil?
        super(context, ignore_layout, reset_context, locals)
      else
        @content_block.call
      end
    end

    def useLayout?
      !@content_block.nil? or !template.nil?
    end

  end
  
end
