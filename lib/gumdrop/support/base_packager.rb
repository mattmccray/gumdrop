module Gumdrop
  module Support
    module BasePackager

      def compress_output(content, opts)
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
          @site.report "Unknown javascript compressor type! (#{ opts[:compressor] })", :warning
          content
        end
      end
      
      def keep_src(name, content, opts)
        if opts[:keep_src] or opts[:keep_source]
          ext= File.extname name
          page name.gsub(ext, "#{opts.fetch(:source_postfix, '-src')}#{ext}") do
            content
          end
        end
      end
      
      def prune_src(name, opts)
        if opts[:prune] and opts[:root]
          sp = File.expand_path( @site.config.source_dir )
          rp = File.expand_path(opts[:root])
          relative_root = rp.gsub(sp, '')[1..-1]
          rrlen= relative_root.length - 1
          @site.content_hash.keys.each do |path|
            if path[0..rrlen] == relative_root and name != path
              @site.content_hash.delete path
            end
          end
        end
      end

    end
  end
end