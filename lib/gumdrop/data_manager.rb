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
  
  class DataManager
    attr_reader :cache
  
    def initialize(data_dir="data")
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

    # TODO: This is not a great place for this. MOVE IT!
    # This'll go on the Site class for query support: .find()/.all()/.paths()/.nodes()
    def site
      site= Hash.new {|h,k| h[k]= nil }
      Gumdrop.site.keys.sort.each do |path|
        unless Gumdrop.greylist.any? {|pattern| path_match path, pattern }
          site[path]= Gumdrop.site[path]    
        end
      end
      site
    end
    # Oh dear god! This belongs elsewhere!
    def path_match(path, pattern)
      File.fnmatch pattern, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_CASEFOLD
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
        load_from_yamldb path
      elsif File.extname(path) == ""
        load_from_directory path
      else
        load_from_file path
      end
    end

    def load_from_file( filename )
      ext=File.extname(filename)
      if ext == '.yamldoc' or ext == '.ymldoc'
        load_from_yamldoc filename
      elsif ext == '.yaml' or ext == '.yml' or ext == '.json'
        hashes2ostruct( YAML.load_file(filename)  )
      else
        raise "Unknown data type (#{ext}) for #{filename}"
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

    def load_from_yamldoc( filename )
      source = File.read(filename)

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
      Dir[ File.join( "#{filepath}", "{*.yaml,*.json,*.yml,*.yamldoc,*.ymldoc}" ) ].each do |filename|
        # Gumdrop.report ">> Loading data file: #{filename}"
        id= File.basename filename
        obj_hash= load_from_file filename
        obj_hash._id = id
        all << obj_hash
      end
      all
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

  class YamlDoc

  end
end