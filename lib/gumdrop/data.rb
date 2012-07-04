# require 'ostruct'

module Gumdrop

  class DataManager
    include Util::SiteAccess

    attr_reader :cache
  
    def initialize(data_dir="./data")
      @dir= File.expand_path data_dir
      # reset
      @cache= Hash.new &method(:_cache_dataset)
    end

    def dir=(path)
      @dir= File.expand_path path
    end
  
    def method_missing(key, value=nil)
      @cache[key]
    end
  
    def set(key, value)
      @cache[key]= value
    end
  
    def reset
      @cache.clear
    end

    def contents(pattern=nil, opts={})
      if pattern.nil?
        site.contents.all
      else
        site.contents(pattern, opts)
      end
    end
    
    def pager_for(key, opts={})
      data= case key
        when Symbol
          @cache[key]
        when Array
          key
        else
          raise "pager_for requires a lookup symbol or array data."
        end
      base_path= opts.fetch(:base_path, 'page')
      page_size= opts.fetch(:page_size, 5)
      Util::Pager.new( data, base_path, page_size )
    end
  
  private
  
    def _cache_dataset(hash, key)
      hash[key]= load_data(key) #unless @cache.has_key? key
    end

    def load_data(key)
      path=_get_filename key 
      return nil if path.nil?
      if File.directory? path
        _load_from_directory path
      else
        _load_from_file path
      end
    end

    def _load_from_file( filename )
      ext=File.extname(filename)[1..-1]
      provider= Data::Provider.for ext
      case
        when provider.nil?
          raise "Unknown data type (#{ext}) for #{filename}"
        when provider.available?
          data= provider.data_for filename
          log.debug "    loaded: #{filename}"
          data
        else
          raise "Unavailable data type (#{ext}) for #{filename}"
      end
    end

    def _load_from_directory( filepath )
      all=[]
      Dir[ filepath / _supported_type_glob ].each do |filename|
        id= File.basename(filename).gsub(File.extname(filename), '')
        obj_hash= _load_from_file filename
        obj_hash._id = id
        all << obj_hash
      end
      all
    end

    def _get_filename(path)
      lpath= _local_path_to(path)
      if File.directory? lpath
        lpath
      else
        _registered_data_types.each do |ext|
          lpath= _local_path_to("#{path}.#{ext}")
          return lpath if File.exists? lpath
        end
        log.warn "No data found for #{path}"
        nil
      end
    end

    def _local_path_to(filename)
      File.join(@dir.to_s, filename.to_s)
    end

    def _registered_data_types
      Data::Provider.registered_exts
    end

    def _supported_type_glob
      "{*.#{ _registered_data_types.join ',*.'}}"
    end

  end

  module Data
    # Base class for Data Proviers
    class Provider
      
      def available?
        raise "available? must be implemented! (#{self.class})"
      end

      def data_for(filepath)
        raise "data_for must be implemented! (#{self.class})"
      end

      def supply_data(object)
        case object
          when Hash
            object = object.clone
            object.each do |key, value|
              object[key] = supply_data(value)
            end
            # OpenStruct.new(object)
            Gumdrop::Util::HashObject.from object
          when Array
            object = object.clone
            object.map! { |item| supply_data(item) }
          else
            object
        end
      end

      class << self

        def extensions(*extnames)
          provider_class= self
          @@providers ||= {}
          extnames.each do |ext|
            @@providers[ext.to_s]= provider_class
          end
        end
        alias_method :extension, :extensions

        def registered_exts
          @@providers.keys
        end

        def for(ext)
          case
            when provider_class= @@providers[ext]
              provider_class.new
            when provider_class= @@providers[".#{ ext }"]
              provider_class.new
            else
              nil
          end
        end
      end
    end
  end
end

Dir[File.dirname(__FILE__) / 'data_providers' / '*.rb'].each do |lib|
  require lib
end