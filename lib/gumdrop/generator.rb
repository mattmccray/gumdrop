module Gumdrop

  class Generator
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
    
    def execute
      if @content.is_a? Proc
        run_dsl_from_proc @content
      else
        run_dsl_from_source IO.readlines(@content.path).join('')
      end
    end
    
    def data
      @site.data
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
      content= GeneratedContent.new(filepath, block, @site, opts)
      if opts.has_key? :template and !opts[:template].nil?
        content.template = if @site.layouts.has_key?( opts[:template] )
          @site.layouts[ opts[:template] ]
        else
          @site.layouts[ "#{opts[:template]}.template" ]
        end.template
      end
      
      @site.node_tree[content.uri]= content
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
    
    def stitch(name, opts)
      require 'gumdrop/stitch_ex'
      require 'gumdrop/stitch_compilers'
      content= Stitch::Package.new(opts).compile
      page name do
        case opts[:compress]

        when true, :jsmin
          require 'jsmin'
          JSMin.minify content

        when :yuic
          require "yui/compressor"
          compressor = YUI::JavaScriptCompressor.new(:munge => opts[:obfuscate])
          compressor.compress(content)

        when :uglify
          require "uglifier"
          Uglifier.compile( content, :mangle=>opts[:obfuscate])

        when false
          content

        else
          # UNKNOWN Compressor type!
          @site.report "Unknown javascript compressor type! (#{ opts[:compressor] })", :warning
          content
        end
      end
      if opts[:keep_src] or opts[:keep_source]
        ext= File.extname name
        page name.gsub(ext, "#{opts.fetch(:source_postfix, '-src')}#{ext}") do
          content
        end
      end
      if opts[:prune] and opts[:root]
        sp = File.expand_path( @site.config.source_dir )
        rp = File.expand_path(opts[:root])
        relative_root = rp.gsub(sp, '')[1..-1]
        rrlen= relative_root.length - 1
        @site.node_tree.keys.each do |path|
          if path[0..rrlen] == relative_root and name != path
            @site.node_tree.delete path
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

    def initialize(path, block, site, params={})
      @content_block= block
      super(path, site, params)
    end

    def render(context=nil, ignore_layout=false,  reset_context=true, locals={})
      if @content_block.nil?
        super(context, ignore_layout, reset_context, locals)
      else
        @content_block.call
      end
    end

    def useLayout?
      !@content_block.nil? or !@template.nil?
    end

  end
  
end
