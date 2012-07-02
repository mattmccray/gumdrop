# FIXME: Abstract Compressors!

module Gumdrop
  module Support
    class Compressor
      include Gumdrop::Util::Loggable

      def compress(content, opts)
        case opts[:compress]

        when true, :jsmin
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

        when false
          content

        else
          # UNKNOWN Compressor type!
          log.warn "Unknown javascript compressor type! (#{ opts[:compressor] })"
          content
        end
      end
    end
  end
end

