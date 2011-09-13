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
  
    def initialize
      #puts "@!@"
      @cache= {}
      @persisted= {}
    end
  
    def method_missing(key, value=nil)
      cache_or_load_data(key)
      @cache[key]
    end
  
    def set(key, value, opts={})
      @cache[key]= value
      @persisted[key]= value #unless opts[:persist] == false
    end
  
    def reset
      @cache= @persisted.clone #Hash.new(@persisted)  #{|h,k| h[k]= load_data(k) }
    end
    
    def pager_for(key, opts={})
      base_path= opts.fetch(:base_path, 'page')
      page_size= opts.fetch(:page_size, 5)
      data= if key.is_a? Symbol
        cache_or_load_data(key)
        @cache[key]
      else
        key
      end
      Pager.new( data, base_path, page_size )
    end
  
  
  private
  
    def cache_or_load_data(key)
      @cache[key]= load_data(key) unless @cache.has_key? key
    end

    def load_data(key)
      path=get_filename(key)
      return nil if path.nil?
      if File.extname(path) == ".yamldb"
        docs=[]
        File.open(path, 'r') do |f|
          YAML.load_documents(f) do |doc|
            docs << hashes2ostruct( doc ) unless doc.has_key?("__proto__")
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
        #nil #TODO: Should it die if it can't find data?
      end
    end
  end
end