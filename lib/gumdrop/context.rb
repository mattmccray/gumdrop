
module Gumdrop
  
  class Context
    include ::Gumdrop::ViewHelpers
    
    attr_accessor :state

    def initialize(site)
      @site= site
      # puts "NEW CONTEXT!!!"
    end
    
    def uri(path, opts={})
      path= path[1..-1] if path.starts_with?('/') # and path != "/"
      uri_string= if !@site.config.relative_paths or force_absolute
        "/#{path}"
      else
        "#{'../'*@state['current_depth']}#{path}"
      end
      if opts[:fresh] and @site.node_tree.has_key?(path)
        uri_string += "?v=#{ @site.node_tree[path].mtime.to_i }"
      end
      uri_string = "/" if uri_string == ""
      uri_string
    end
    
    def url(path)
      path= path[1..-1] if path.starts_with?('/')
      "#{@site.config.site_url}/#{path}"
    end
  
    def slug
      @state['current_slug']
    end
    
    def get_template
      layout= @state['layout']
      @state['layout']= nil
      unless layout.nil?
        @site.layouts["#{layout}.template"]
      else
        nil
      end
    end
    
    def use_template(name)
      @state['layout']= name
    end
    alias_method :use_layout, :use_template
    
    def render(path, opts={})
      page= get_page path
      unless page.nil?
        #TODO: nested state for an inline rendered page?
        old_layout= @state['layout']
        content= page.render(nil, true, false, opts)
        old_layout= @state['layout']
        content
      else
        ""
      end
    end
    
    def data
      @site.data
    end

    def site
      @site
    end

    # Access to settings as defined in the configure block
    def config
      @site.config
    end
  
    def reset_data(preset={})
      @state = preset
    end

    def method_missing(name, value=nil)
      @state=  Hash.new {|h,k| h[k]= nil } if @state.nil? 
      unless value.nil?
        @state[name.to_s]= value
      else
        @state[name.to_s]
      end
    end
    
    def params
      @content.params
    end
    
    def set_content(content, locals)
      @content= content
      @state= @state.reverse_merge(content.params).merge(locals)
    end
    
    def content_for(key, &block)
      keyname= "_content_#{key}"
      if block_given?
        @state[keyname]= block
        nil
      else
        if @state.has_key?(keyname)
          @state[keyname].call
        else
          nil
        end
      end
    end
    
    def content_for?(key)
      keyname= "_content_#{key}"
      @state.has_key?(keyname)
    end
    
  protected
    
    def get_page(path)
      page= @site.node_tree[path]
      page= @site.node_tree["#{path}.html"] if page.nil? # Bit of a hack...
      page= @site.partials[path] if page.nil?
      page= @site.layouts[path] if page.nil? # ???
      page
    end
    
  end
  
end