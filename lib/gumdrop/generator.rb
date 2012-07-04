module Gumdrop

  class Generator
    include Util::SiteAccess

    def initialize(content=nil, opts={}, &block) # block?
      @content= content || block
      @dsl= DSL.new self
      @pages= []
      @filename= content.nil? ? (opts[:filename] || '') : content.filename
      @base_path= content.nil? ? (opts[:base_path] || '') : content.slug 
    end

    def unload
      pages.each do |content|
        site.contents.remove content
      end
      @dsl= DSL.new self
    end

    def reload
      unload
      execute
    end

    def pages
      @pages
    end

    def gen_page(name, opts={}, params={}, &block)
      event_block :generate_item do
        name.relative!
        opts= params.reverse_merge(opts)
        filepath= if @base_path.empty?
            site.source_path / name
          else
            site.source_path / @base_path / name
          end
        if block.nil?
          handler= _render_inline_content opts
          content= site.contents.create filepath, self, &handler          
        else
          content= site.contents.create filepath, self, &block
        end
        content.params.merge! opts
        log.debug " generated: #{content.uri}"
        @pages << content
      end
    end

    def execute
      log.debug "(Generator '#{ @filename }')"
      if @content.is_a? Proc
        if @content.arity == 1
          @content.call @dsl
        else
          @dsl.instance_eval &@content
        end
      else
        @dsl.instance_eval @content.body
      end
      log.debug "   created: #{ @pages.size } pages"
    end

    def _render_inline_content(opts)
      Proc.new {
        renderer= site.active_renderer || Renderer.new
        content= site.resolve(opts[:render], opts)
        opts[:inline_render]= true
        renderer.draw content, opts
      }
    end

    class DSL
      include Util::SiteAccess

      attr_reader :params

      def initialize(generator)
        @generator= generator
        @params= Util::HashObject.new
      end

      def data
        site.data
      end

      def config
        site.config
      end

      def options
        site.options
      end

      def env
        site.env
      end

      def mode
        site.mode
      end

      def set(var_name, value)
        @params[var_name]= value
      end
      def get(var_name)
        @params[var_name]
      end

      def page(name, opts={}, &block)
        @generator.gen_page name, opts, @params, &block
      end
      alias_method :content, :page

      def file(name, opts={}, &block)
        opts[:layout]= opts[:layout] || false
        page name, opts, &block
      end

    end
  end


  class << self

    # Generate a page (based on data or whatever) from your
    # Gumdrop file like this:
    #
    #   Gumdrop.generate 'label' do |gen|
    #     gen.file 'my-page.html' do
    #       # whatever you return is set as the page contents.
    #       "hello!"
    #     end
    #   end
    #
    def generate(name=nil, opts={}, &block)
      opts[:filename]= name unless opts[:filename]
      site.generators << Generator.new(nil, opts, &block)
    end

  end

end

    
