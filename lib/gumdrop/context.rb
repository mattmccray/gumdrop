require 'yaml'
require 'ostruct'

def hashes2ostruct(object)
  return case object
  when Hash
    object = object.clone
    object.each do |key, value|
      object[key] = hashes2ostruct(value)
    end
    OpenStruct.new(object)
  when Array
    object = object.clone
    object.map! { |i| hashes2ostruct(i) }
  else
    object
  end
end

module Gumdrop
  
  module Context
    class << self
      
      attr_accessor :state
      
      def uri(path)
        "#{'../'*@state['current_depth']}#{path}"
      end
      
      def data(path)
        if File.exists? "data/#{path}.json"
          hashes2ostruct( YAML.load_file "data/#{path}.json" )
        elsif File.exists? "data/#{path}.yml"
          hashes2ostruct( YAML.load_file "data/#{path}.yml" )
        else
          raise "No Data"
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
      
      def render(path)
        page= Gumdrop.site[path]
        unless page.nil?
          #TODO: nested state for an inline rendered page?
          old_layout= @state['layout']
          content= page.render(true, false)
          old_layout= @state['layout']
          content
        else
          ""
        end
      end
    
      def reset_data(preset={})
        @state = preset
      end

      def method_missing(name, value=nil)
        @state=  Hash.new {|h,k| h[k]= nil } if @state.nil? 
        unless value.nil?
          @state[name]= value
        else
          @state[name]
        end
      end
    end
  end
  
  
end