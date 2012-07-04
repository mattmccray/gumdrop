
module Gumdrop::Support

  module Compressor

    def compress(content, opts)
      case opts
      when Symbol, String
        do_compress content, opts.to_s.to_sym
      when Hash
        do_compress content, opts[:with].to_s.to_sym, opts
      else
        # UNKNOWN Compressor type!
        log.warn "Unknown javascript compressor type!"
        content
      end
    end

  private

    def do_compress(content, type, opts={})
      case type
        when :jsmin
          require 'jsmin'
          JSMin.minify content

        when :yuic
          require "yui/compressor"
          compressor = YUI::JavaScriptCompressor.new(:munge => opts[:obfuscate])
          compressor.compress(content)

        when :uglify
          require "uglifier"
          Uglifier.compile( content, :mangle=>opts[:obfuscate])

        when :packr
          require 'packr'
          Packr.pack(content, :shrink_vars => true, :base62 => false, :private=>false)

        else
          # UNKNOWN Compressor type!
          log.warn "Unknown javascript compressor type! (#{ type })"
          content
      end
    end

  end
  
  Gumdrop::Generator::DSL.send :include, Compressor

end

