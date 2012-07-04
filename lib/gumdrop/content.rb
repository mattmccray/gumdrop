module Gumdrop

  # All content (layouts, partials, images, html, js css, etc) found in
  # the source directory are represented as a Content object in memory
  class Content
    include Util::SiteAccess

    attr_reader :source_path, :params
    
    def initialize(source_path, generator=nil, &block)
      @source_path= source_path
      @generator= generator
      @ignore= false
      @block= block
      @params= Util::HashObject.new
    end

    # TODO: Use a Pathname for all path operations instead of File.*
    #       Add support for relative_to and relative_from to 
    #       ContentList (find?)

    def params=(value={})
      @params.merge! value
    end

    def slug
      @slug ||= uri.gsub('/', '-').gsub(ext, '')
    end

    def path
      @path ||= _source_path
    end

    def level
      @level ||= (path.split('/').length - 1)
    end

    def source_filename
      @source_filename ||= File.basename source_path
    end

    def filename
      @filename ||= _target_filename
    end

    def type
      @type ||= File.extname source_filename
    end

    def ext
      @ext ||= File.extname filename
    end

    def uri
      @uri ||= _uri
    end

    def binary?
      @is_binary ||= begin
        if generated? or has_block? or missing?
          false
        else
          # from ptools
          s = (File.read(source_path, File.stat(source_path).blksize) || "").split(//)
          ((s.size - s.grep(" ".."~").size) / s.size.to_f) > 0.30
        end
      end
    end

    # Can I call #body() ?
    def exists?
      has_block? or File.exists? @source_path
    end

    def missing?
      !exists?
    end

    def generated?
      !@generator.nil?
    end

    def has_block?
      !@block.nil?
    end

    def partial?
      source_filename[0] == "_"
    end

    def layout?
      ext == '.layout'
    end

    def generator?
      ext == '.generator'
    end

    def body # Memoize this?
      @body ||= case
        when has_block?
          @block.call
        when missing?, binary?
          nil
        else
          File.read @source_path
        end
    end

    def mtime
      @mtime ||= if exists? and !generated?
          File.new(@source_path).mtime
        else
          Time.now
        end
    end

    def to_s
      uri
    end

  private

    def _uri
      # Do I need to do anything for windoze here to make sure
      # the slashes are / and not \ ?
      uri=  File.dirname(path) / filename
      if uri.starts_with? './'
        uri[2..-1]
      elsif uri.starts_with? '/'
        uri[1..-1]
      else
        uri
      end
    end

    def _source_path
      path= @source_path.gsub site.source_path, ''
      if path[0] == '/'
        path[1..-1] 
      else
        path
      end
    end

    def _target_filename
      filename_parts= source_filename.split('.')
      ext= filename_parts.pop
      while !Renderer.for(ext).nil?
        ext= filename_parts.pop
      end
      filename_parts << ext # push the last file ext back on there!
      fname= filename_parts.join('.')
      if partial?
        fname[1..-1]
      else
        fname
      end
    end

    def self.path_match?(path, pattern)
       File.fnmatch pattern, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_CASEFOLD
    end
  end

  class ContentList < Hash 

    def create(path, generator=nil, &block)
      content= Content.new path, generator, &block
      add content, path
    end

    def add(content, uri=nil)
      uri= content.uri if uri.nil?
      self[uri]= content
      content
    end

    def remove(content)
      uri = content.is_a? String ? content : content.uri
      self.delete uri
    end

    # Returns Array of content objects
    def all(pattern=nil)
      pattern.nil? ? values : find(pattern)
    end

    # Scans the filenames (keys) and uses fnmatch to find maches
    def find(pattern)
      patterns= [pattern].flatten
      contents=[]
      self.each_pair do |path, content|
        patterns.each do |pattern|
          contents << content if Content.path_match? path, pattern
        end
      end
      contents
    end

    def get(key)
      self[key]
    end

    def first(pattern)
      find(pattern).first
    end

  end

  # Keeps a ref to content at full path and just the basename
  class SpecialContentList < ContentList
    
    def initialize(default_ext=false)#, *args)
      @ext= default_ext || ".html"  # ???
      super()
    end

    def add(content, uri=nil)
      uri= content.uri if uri.nil?
      buri = File.basename uri
      self[uri]= content
      self[buri]= content
      content
    end

    def remove(content)
      uri = content.is_a? String ? content : content.uri
      self.delete uri
      self.delete File.basename uri
    end

    # Find isn't fuzzy for Special Content. It looks for full
    # uri or the uri's basename, optionally tacking on @ext
    def find(uri)
      _try_variations_of(uri) do |path|
        content= get path
        return [content] unless content.nil?
      end unless uri.nil?
      []
    end

  private

    def _try_variations_of(uri)
      # try the uri
      yield uri
      # plus default ext
      yield uri + @ext
      urip= Pathname.new uri
      # just the filename
      yield urip.basename
      # filename plus default extension
      yield urip.basename + @ext
      # filename minus the ext
      yield urip.basename.to_s.gsub urip.extname, ''
      # uri minus ext
      yield uri.gsub urip.extname, ''
    end

  end
end
