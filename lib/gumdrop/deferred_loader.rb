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
  
    def initialize(data_dir="data")
      #puts "@!@"
      @dir= data_dir
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
  
    def reset(hard=false)
      if hard
        @cache={}
        @persisted={}
      else
        @cache= @persisted.clone #Hash.new(@persisted)  #{|h,k| h[k]= load_data(k) }
      end
    end

    def site
      # TODO: This is not a great place for this!
      site= Hash.new {|h,k| h[k]= nil }
      Gumdrop.site.keys.sort.each do |path|
        unless Gumdrop.greylist.any? {|p| path.starts_with?(p) }
          site[path]= Gumdrop.site[path]    
        end
      end
      site
    end

    def site_all
      Gumdrop.site
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
      @persisted[key]= @cache[key] # New persist data loaded from file?
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
      elsif File.extname(path) == ""
        all=[]
        Dir[ File.join( "#{path}", "{*.yaml,*.json,*.yml}" ) ].each do |filename|
          # Gumdrop.report ">> Loading data file: #{filename}"
          id= File.basename filename
          raw_hash= YAML.load_file(filename) 
          raw_hash['_id']= id
          obj_hash= hashes2ostruct( raw_hash )
          all << obj_hash
        end
        all
      else
        hashes2ostruct( YAML.load_file(path)  )
      end
    end

    def get_filename(path)
      if File.exists? local_path_to("#{path}.json")
        local_path_to "#{path}.json"
      elsif File.exists? local_path_to("#{path}.yml")
        local_path_to "#{path}.yml"
      elsif File.exists? local_path_to("#{path}.yaml")
        local_path_to  "#{path}.yaml"
      elsif File.exists? local_path_to("#{path}.yamldb")
        local_path_to "#{path}.yamldb"
      elsif File.directory? local_path_to(path)
        local_path_to(path)
      else
        #FIXME: Should it die if it can't find data?\
        # raise "No data found for #{path}"
        Gumdrop.report "No data found for #{path}", :warning
        nil
      end
    end

    def local_path_to(filename)
      File.join(@dir.to_s, filename.to_s)
    end
  end
end