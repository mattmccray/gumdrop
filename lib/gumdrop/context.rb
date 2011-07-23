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
  
  class DeferredLoader
    attr_reader :cache
    
    # def initialize
    #   puts "@!@"
    # end
        
    def method_missing(key, value=nil)
      @cache= Hash.new {|h,k| h[k]= load_data(k) } if @cache.nil?
      @cache[key]
    end
    
  private
  
    def load_data(key)
      path=get_filename(key)
      if File.extname(path) == ".yamldb"
        docs=[]
        File.open(path, 'r') do |f|
          YAML.load_documents(f) do |doc|
            docs << hashes2ostruct( doc )
          end
        end
        docs
      else
        hashes2ostruct( YAML.load_file(path)  )
      end
    end
  
    # TODO: Support './data/collection_name/*.(yaml|json)' data loading?
  
    def get_filename(path)
      if File.exists? "data/#{path}.json"
        "data/#{path}.json"
      elsif File.exists? "data/#{path}.yml"
        "data/#{path}.yml"
      elsif File.exists? "data/#{path}.yaml"
        "data/#{path}.yaml"
      elsif File.exists? "data/#{path}.yamldb"
        "data/#{path}.yamldb"
      else
        raise "No data found for #{path}"
      end
    end
  end
  
  module Context
    class << self
      
      include ::Gumdrop::ViewHelpers
      
      attr_accessor :state
      attr_reader :data
      
      def uri(path)
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
      
      def render(path)
        page= get_page path
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
        # TODO: Add a setting for reloading data on every request/page
        @data= DeferredLoader.new if @data.nil? or !Gumdrop.config.cache_data
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