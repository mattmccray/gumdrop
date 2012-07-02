module Gumdrop::Util

  class Scanner
    include Loggable

    attr_reader :options

    def initialize(base_path, opts={}, &block)
      @source_glob= base_path / "**" / "*"
      @options= opts
      @src_path= base_path
      @validator= block || method(:_default_validator)
    end

    def each
      Dir.glob(@source_glob, File::FNM_DOTMATCH).each do |path|
        rel_path= _relative(path)
        unless should_skip? rel_path, path
          yield path, rel_path
        else
          log.debug " excluding: #{ rel_path }"
        end
      end
    end

    def should_skip?(path, full_path)
      return true if File.directory?(full_path)
      @validator.call(path, full_path) || false
    end

  private

    def _default_validator(src,full)
      true
    end

    def _relative(path)
      relpath= path.gsub @src_path, ''
      if relpath[0]== '/'
        relpath[1..-1]
      else
        relpath
      end
    end
  end

end
