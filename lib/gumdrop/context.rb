
module Gumdrop
  
  module Context
    class << self
      
      include ::Gumdrop::ViewHelpers
      
      attr_accessor :state
      #attr_reader :data
      
      def uri(path, opts={})
        path= path[1..-1] if path.starts_with?('/') # and path != "/"
        uri_string= if !Gumdrop.config.relative_paths or Context.force_absolute
          "/#{path}"
        else
          "#{'../'*@state['current_depth']}#{path}"
        end
        if opts[:fresh] and Gumdrop.site.has_key?(path)
          uri_string += "?v=#{ Gumdrop.site[path].mtime.to_i }"
        end
        uri_string = "/" if uri_string == ""
        uri_string
      end
      
      def url(path)
        path= path[1..-1] if path.starts_with?('/')
        "#{Gumdrop.config.site_url}/#{path}"
      end
    
      def slug
        @state['current_slug']
      end
      
      def get_template
        layout= @state['layout']
        @state['layout']= nil
        unless layout.nil?
          Gumdrop.layouts["#{layout}.template"]
        else
          nil
        end
      end
      
      def use_template(name)
        @state['layout']= name
      end
      
      def render(path, opts={})
        page= get_page path
        unless page.nil?
          #TODO: nested state for an inline rendered page?
          old_layout= @state['layout']
          content= page.render(true, false, opts)
          old_layout= @state['layout']
          content
        else
          ""
        end
      end
      
      def data
        Gumdrop.data
      end

      # Access to settings from configure block
      def config
        Gumdrop.config
      end
    
      def reset_data(preset={})
        # TODO: Add a setting for reloading data on every request/page
        #  was this for the server?
        Gumdrop.data.reset if !Gumdrop.config.cache_data
        @state = preset
      end

      def method_missing(name, value=nil)
        @state=  Hash.new {|h,k| h[k]= nil } if @state.nil? 
        # puts "Looking for >> #{name} in #{@state.keys}"
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
        page= Gumdrop.site[path]
        page= Gumdrop.site["#{path}.html"] if page.nil? # Bit of a hack...
        page= Gumdrop.partials[path] if page.nil?
        page= Gumdrop.layouts[path] if page.nil? # ???
        page
      end
      
    end
  end
  
  
end