
module Gumdrop
  
  module Context
    class << self
      
      include ::Gumdrop::ViewHelpers
      
      attr_accessor :state
      #attr_reader :data
      
      def uri(path)
        path= path[1..-1] if path.starts_with?('/')
        if Gumdrop.config.relative_paths
          "#{'../'*@state['current_depth']}#{path}"
        else
          "/#{path}"
        end
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
    
      def reset_data(preset={})
        # TODO: Add a setting for reloading data on every request/page
        #@data= DeferredLoader.new if @data.nil? or !Gumdrop.config.cache_data
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
        @state= @state.reverse_merge(content.params).reverse_merge(locals)
      end
      
    protected
      
      def get_page(path)
        page= Gumdrop.site[path]
        page= Gumdrop.site["#{path}.html"] if page.nil? # Bit of a hack...
        page= Gumdrop.partials[path] if page.nil?
        page
      end
      
    end
  end
  
  
end