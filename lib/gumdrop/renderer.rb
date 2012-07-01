module Gumdrop

  class Renderer
    include Util::SiteAccess

    MUNGABLE_RE= Regexp.new(%Q<(href|data|src)([\s]*)=([\s]*)('|"|&quot;|&#34;|&#39;)?\\/([\\/]?)>, 'i')

    attr_reader :context

    def initialize
      @content= nil
      @context= nil
      @opts= nil
    end

    def draw(content, opts={})
      event_block :render_item, true do |data|
        data[:content]= content
        log.debug " rendering: #{ content.source_filename } (#{ content.uri })"
        if content.binary? or content.missing?
          log.warn "Missing content body for: #{ content.uri }"
          nil
        else
          _in_context(content, opts) do
            data[:context]= @context
            data[:output]= _render_content!
          end
        end
      end
    end

    private

      def _render_content!
        output= @content.body
        _render_pipeline(@content.source_filename) do |template_class|
          output= _render_text(output, template_class)
        end
        output= _render_layouts output #unless @use_layout
        _relativize_uris output
      end

      def _render_text(text, template_class, sub_content="")
        log.debug "            #{ template_class.to_s }"
        template= template_class.new(@content.source_path) { text }
        template.render(@context, content:sub_content) { sub_content }
      end

      def _render_layouts(text)
        layout = _layout_for_content
        unless layout.nil?
          text= _render_layout text, layout
          # Nested Layouts!
          sub_layout= _sub_layout(layout)
          while !sub_layout.nil?
            text= _render_layout text, sub_layout
            sub_layout= _sub_layout(sub_layout)
          end 
        end
        text
      end

      def _render_layout(text, layout)
        log.debug "    layout: #{layout.source_filename}"
        layout_body= layout.body
        _render_pipeline(layout.source_filename) do |layout_class|
          text = _render_text(layout_body, layout_class, text)
        end
        text
      end

      def _render_pipeline(path)
        filename_parts= path.split('.')
        begin
          ext= filename_parts.pop
          tc= Renderer.for(ext)
          yield tc unless tc.nil?
        end while !tc.nil? #and filename_parts.size
      end

      def _relativize_uris(text)
        if _relativize?
          path_to_root= _path_to_root
          text.force_encoding("UTF-8") if text.respond_to? :force_encoding
          text = text.gsub MUNGABLE_RE do |match|
            if $5 == '/'
              "#{ $1 }#{ $2 }=#{ $3 }#{ $4 }/"
            else
              "#{ $1 }#{ $2 }=#{ $3 }#{ $4 }#{ path_to_root }"
            end
          end
        end
        text
      end

      def _relativize?
        return false if !site.config.relative_paths
        return false if @context.force_absolute
        return true if site.config.relative_paths_exts == :all
        site.config.relative_paths_exts.include?(@content.ext)
      end

      def _layout_for_content
        if @opts[:force_partial] or (@content.partial? and !@opts[:layout])
          nil
        else
          layout= @opts[:layout] || @context.get(:layout)
          site.layouts.first layout
        end
      end

      def _sub_layout(layout)
        sub_layout_name= @context.get :layout
        return nil if sub_layout_name.nil?

        sub_layout= site.layouts.first sub_layout_name
        return nil if sub_layout.nil?
        return nil if sub_layout.uri == layout.uri

        sub_layout
      end


      def _default_layout
        if site.config.layout_exts.include? @content.ext
          site.config.default_layout
        else
          nil
        end
      end

      def _path_to_root
        '../' * @content.level
      end

      def _in_context(content, opts)
        _new_context(content, opts)
        output= yield
        _revert_context
        output
      end

      def _new_context(content, opts)
        @old_context= @context
        @old_content= @content
        @old_opts= @opts
        @context= RenderContext.new content, self, @old_context
        @content= content
        @opts= opts
        if @old_context.nil? # won't be nil for partials and layouts
          @context.set :layout, _default_layout
        end
      end

      def _revert_context
        @context= @old_context
        @content= @old_content
        @opts= @old_opts
      end

    class << self
      def for(ext)
        Tilt[ext] 
      rescue LoadError # stupid tilt and redcarpet, they don't play well together
        nil
      end
    end
  end

  class RenderContext
    include Util::SiteAccess
    include Util::ViewHelpers

    attr_reader :content, :state

    def initialize(content, renderer, parent=nil)
      @content= content
      @renderer= renderer
      @parent= parent
      @state= {}
    end

    def render(path, opts={})
      content= site.contents.first(path) || site.partials.first(path)
      raise StandardError, "Content or Partial cannot be found at: #{path}" if content.nil?
      opts[:force_partial]= opts.has_key?(:layout) ? false : true
      @renderer.draw content, opts
    end

    def get(key)
      _get_from_state key.to_sym
    end

    def set(key, value=nil)
      if key.is_a? Hash
        key.each do |k,v|
          @state[k.to_s.to_sym]= v
        end
      else
        @state[key.to_s.to_sym]= value
      end
    end

    def method_missing(sym, *args, &block)
      if sym.to_s.ends_with? '='
        key= sym.to_s.chop
        set key, args[0]
      else
        get(sym)
      end
    end

  private

    def _get_from_state(key)
      if @state.has_key? key
        @state[key]
      else
        _get_from_parent key
      end
    end

    def _get_from_parent(key)
      if @parent.nil? or !@parent.has_key?(key)
        _get_from_content key 
      else
        @parent.get key
      end
    end

    def _get_from_content(key)
      return nil if @content.nil?
      return @content.send(key.to_sym) if @content.respond_to?(key.to_sym)
      return @content.params[key] if !@content.params.has_key?(key)
      nil
    end

  end

end