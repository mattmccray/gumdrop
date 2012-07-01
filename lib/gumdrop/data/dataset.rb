require 'yaml'
require 'ostruct'

module Gumdrop

  # Supported Data File Types:
  DATA_DOC_EXTS= %w(json yml yaml ymldb yamldb yamldoc ymldoc)

  class DataManager
    attr_reader :cache
  
    def initialize(site, data_dir="./data")
      @site= site
      @dir= File.expand_path data_dir
      @cache= {}
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

    def site(pattern=nil, opts={})
      @site.contents(pattern, opts)
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
      Pager.new( data, base_path, page_size )
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
        Gumdrop.report "Unknown data type (#{ext}) for #{filename}", :warning
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
        # Gumdrop.report ">> Loading data file: #{filename}"
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
        Gumdrop.report "No data found for #{path}", :warning
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

  class Pager
    attr_reader :all, :pages, :base_url, :current_page, :page_sets

    def initialize(articles, base_path="/page", page_size=5)
      @all= articles
      @page_size= page_size
      @base_path= base_path
      @page_sets= @all.in_groups_of(page_size, false)
      @pages= []
      @current_page=1
      @page_sets.each do |art_ary|
        @pages << HashObject.from({
          items: art_ary,
          page: @current_page,
          uri: "#{base_path}/#{current_page}",
          pager: self
        })
        @current_page += 1
      end
      @current_page= nil
    end

    def length
      @pages.length
    end

    def first
      @pages.first
    end

    def last
      @pages.last
    end

    def each
      @current_page=1
      @pages.each do |page_set|
        yield page_set
        @current_page += 1
      end
      @current_page= nil
    end

    def [](key)
      @pages[key]
    end
  end

end