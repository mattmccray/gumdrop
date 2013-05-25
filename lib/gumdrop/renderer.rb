module Gumdrop

  class Renderer
    include Util::SiteAccess

    SPECIAL_OPTS= %w(layout force_partial)
    MUNGABLE_RE= Regexp.new(%Q<(href|data|src)([\s]*)=([\s]*)('|"|&quot;|&#34;|&#39;)?\\/([\\/]?)>, 'i')

    attr_reader :context, :cache

    def initialize
      site.active_renderer= self
      @context, @content, @opts= nil, nil, nil
      @stack= []
      @cache= {}
    end

    def draw(content, opts={})
      event_block :render_item do |data|
        data[:content]= content
        log.debug " rendering: #{ content.source_filename } (#{ content.uri })"
        if content.binary? or content.missing?
          log.warn "Missing content body for: #{ content.uri }"
          nil
        else
          opts[:calling_page]= @context unless opts.has_key? :calling_page
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
      output= _render_layouts output
      _relativize_uris output
    end

    def _render_text(text, template_class, sub_content="")
      log.debug "            #{ template_class.to_s }"
      template= template_class.new(@content.source_path) { text }
      template.render(@context, content:sub_content) { sub_content }
    end

    def _render_layouts(text)
      _layout_pipeline do |layout_class|
        text= _render_layout text, layout_class
      end
      text
    end

    def _render_layout(text, layout)
      log.debug "    layout: #{layout.source_filename}"
      _render_pipeline(layout.source_filename) do |layout_class|
        text = _render_text(layout.body, layout_class, text)
      end
      text
    end

    # NOTE: Currently, the render pipeline ends when Renderer.for
    # returns nil for an ext. Should it continue on until all the
    # possible file ext templates are looked up?
    def _render_pipeline(path)
      filename_parts= path.split('.')
      begin
        ext= filename_parts.pop
        template_class= Renderer.for(ext)
        yield template_class unless template_class.nil?
      end while !template_class.nil? #and filename_parts.size
    end

    def _layout_pipeline
      layout = _layout_for_content
      unless layout.nil?
        yield layout
        # Nested Layouts!
        sub_layout= _sub_layout_for(layout)
        while !sub_layout.nil?
          yield sub_layout
          sub_layout= _sub_layout_for(sub_layout)
        end 
      end 
    end

    def _relativize_uris(text)
      return text unless _relativize?
      path_to_root= _path_to_root
      text.force_encoding("UTF-8") if text.respond_to? :force_encoding
      text.gsub MUNGABLE_RE do |match|
        if $5 == '/'
          "#{ $1 }#{ $2 }=#{ $3 }#{ $4 }/"
        else
          "#{ $1 }#{ $2 }=#{ $3 }#{ $4 }#{ path_to_root }"
        end
      end
    end

    def _relativize?
      return false if !site.config.relative_paths
      return false if @context.force_absolute
      return false if @content.partial?
      return true if site.config.relative_paths_exts == :all
      site.config.relative_paths_exts.include?(@content.ext)
    end

    def _layout_for_content
      case
        when @opts[:inline_render] then nil
        when (@content.params.has_key?(:layout) and !@content.params.layout) then nil
        # when (@content.partial? and !@opts[:layout] and !@content.params.layout) then nil
        else
          layout= @opts[:layout] || @content.params.layout || @context.get(:layout)
          site.layouts.first layout
      end
    end

    def _sub_layout_for(layout)
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
      @stack.push({
        content: @content,
        context: @context,
        opts: @opts
      }.to_hash_object)
      @context= RenderContext.new content, self, @context
      safe_opts= opts.reject { |o| SPECIAL_OPTS.include? o.to_s }
      @context.set safe_opts
      @content= content
      @opts= opts
      if @stack.size == 1
        @context.set :layout, _default_layout
      end
    end

    def _revert_context
      prev= @stack.pop
      case @opts[:hoist]
        when :all, true
          _hoist_data(prev.context)
        when Array
          _hoist_data(prev.context, @opts[:hoist])
      end
      @context= prev.context
      @content= prev.content
      @opts= prev.opts
    end

    def _hoist_data(to_context, keys=nil)
      keys ||= @context.state.keys
      safe_keys= keys.reject {|k| SPECIAL_OPTS.include? k.to_s }
      safe_keys.each do |key|
        to_context.set key, @context.state[key]
      end
    end

    def _previous
      @stack.last
    end

    class << self

      # Returns the `Tilt::Template` for the given `ext` or nil
      def for(ext)
        Tilt[ext] 
      rescue LoadError # stupid tilt and redcarpet, they don't play well together!
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

    def render(path=nil, opts={})
      content= site.resolve path, opts
      raise StandardError, "Content or Partial cannot be found at: #{path} (#{opts})" if content.nil?
      opts[:force_partial]= true
      opts[:calling_page]= self
      if opts[:cache]
        unless @renderer.cache.has_key? content.source_path
          @renderer.cache[content.source_path]= @renderer.draw content, opts
        end
        @renderer.cache[content.source_path]
      else
        @renderer.draw content, opts
      end
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

    def page
      @content_page ||= begin
        parent= self
        while !parent.nil? and !parent.calling_page.nil? do
          parent= parent.calling_page
        end 
        parent
      end
    end

    def content_for(key, &block)
      keyname= "_content_#{key}"
      if block_given?
        content= capture &block
        @state[keyname]= content #block
        nil
      else
        if @state.has_key?(keyname)
          # @state[keyname].call
          @state[keyname]
        else
          nil
        end
      end
    end

    def capture(&block)
      erbout = eval('_erbout', block.binding) rescue nil
      unless erbout.nil?
        erbout_length = erbout.length
        block.call
        content = erbout[erbout_length..-1]
        erbout[erbout_length..-1] = ''
      else
        content= block.call
      end
      content
    end
    
    def content_for?(key)
      keyname= "_content_#{key}"
      @state.has_key?(keyname)
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
      return @content.params[key] if @content.params.has_key?(key)
      nil
    end

  end

end