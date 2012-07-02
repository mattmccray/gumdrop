require 'yaml'
require 'ostruct'

# TODO: Abstract/Extract data types and loaders,
#       Allow multiple data source foloders.

module Gumdrop

  # Supported Data File Types:
  DATA_DOC_EXTS= %w(json yml yaml ymldb yamldb yamldoc ymldoc)

  class DataManager
    include Util::SiteAccess

    attr_reader :cache
  
    def initialize(data_dir="./data")
      @dir= File.expand_path data_dir
      @cache= {}
    end

    def dir=(path)
      @dir= File.expand_path path
    end
  
    def method_missing(key, value=nil)
      cache_dataset(key)
      @cache[key]
    end
  
    def set(key, value)
      @cache[key]= value
    end
  
    def reset
      @cache={}
    end

    def contents(pattern=nil, opts={})
      if pattern.nil?
        site.contents.all
      else
        site.contents(pattern, opts)
      end
    end
    
    def pager_for(key, opts={})
      base_path= opts.fetch(:base_path, 'page')
      page_size= opts.fetch(:page_size, 5)
      data= if key.is_a? Symbol
        cache_dataset(key)
        @cache[key]
      else
        key
      end
      Util::Pager.new( data, base_path, page_size )
    end
  
    # Exposing these publicly because, well, they're useful:
    def load_from_file( filename )
      ext=File.extname(filename)
      if ext == '.yamldoc' or ext == '.ymldoc'
        load_from_yamldoc filename
      elsif ext == '.yamldb' or ext == '.ymldb'
        load_from_yamldb filename
      elsif ext == '.yaml' or ext == '.yml' or ext == '.json'
        hashes2ostruct( YAML.load_file(filename)  )
      else
        # raise "Unknown data type (#{ext}) for #{filename}"
        log.warn "Unknown data type (#{ext}) for #{filename}"
        nil
      end
    end
    def load_yamldoc(filename, source=nil)
      load_from_yamldoc filename, source
    end

  
  private
  
    def cache_dataset(key)
      @cache[key]= load_data(key) unless @cache.has_key? key
    end

    def load_data(key)
      path=get_filename key 
      return nil if path.nil?
      if File.directory? path
        load_from_directory path
      else
        load_from_file path
      end
    end

    def load_from_yamldb( filename )
      docs=[]
      File.open(filename, 'r') do |f|
        YAML.load_documents(f) do |doc|
          docs << hashes2ostruct( doc ) unless doc.has_key?("__proto__")
        end
      end
      docs
    end

    def load_from_yamldoc( filename, source=nil )
      source = File.read(filename) if source.nil?

      if source =~ /^(\s*---(.+)---\s*)/m
        yaml = $2.strip
        content = source.sub($1, '')
        data= YAML.load(yaml)
      else
        content= source
        data={}
      end

      content_set= false
      data.each_pair do |key, value|
        if value == '_YAMLDOC_'
          data[key]= content
          content_set= true
        end
      end

      data['content']= content unless content_set
      
      hashes2ostruct(data)
    end

    def load_from_directory( filepath )
      all=[]
      Dir[ File.join "#{filepath}", "{*.#{ DATA_DOC_EXTS.join ',*.'}}" ].each do |filename|
        log.debug ">> Loading data file: #{filename}"
        id= File.basename filename
        obj_hash= load_from_file filename
        obj_hash._id = id
        all << obj_hash
      end
      all
    end

    def get_filename(path)
      lpath= local_path_to(path)
      if File.directory? lpath
        lpath
      else
        DATA_DOC_EXTS.each do |ext|
          lpath= local_path_to("#{path}.#{ext}")
          return lpath if File.exists? lpath
        end
        log.warn "No data found for #{path}"
        nil
      end
    end

    def local_path_to(filename)
      File.join(@dir.to_s, filename.to_s)
    end

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

  end

end