require 'digest/md5'

module Gumdrop
  
  module Util
    module ViewHelpers
      
      def hidden(&block)
        #no-op
      end

      def urlencode(string)
        require "erb" unless defined? ERB
        ERB::Util.url_encode(string)
      end
      
      def markdown(source)
        eng_class= Gumdrop::Renderer.for 'markdown'
        unless eng_class.nil?
          eng= eng_class.new { source }
          eng.render
        else
          raise StandardError, "Markdown is not available: Include a Markdown engine in your Gemfile!"
        end
      end
      
      def textile(source)
        eng_class= Gumdrop::Renderer.for 'textile'
        unless eng_class.nil?
          eng= eng_class.new { source }
          eng.render
        else
          raise StandardError, "Textile is not available: Include a Textile engine in your Gemfile!"
        end
      end

      def uri_fresh(path)
        if (path[0] == '/')
          internal_path= path[1..-1]
        else
          internal_path= path
          path= "/#{path}"
        end
        "#{ path }?v=#{ checksum_for internal_path }"
      end

      def cache_bust(path)
        uri_fresh(path)
      end

      def checksum_for(path)
        path= path[1..-1] if path[0] == '/'
        @_checksum_cache ||= {}
        if @_checksum_cache.has_key? path
          @_checksum_cache[path]
        else
          content= render path
          @_checksum_cache[path]= Digest::MD5.hexdigest( content )
        end
      end
      
      def config
        site.config
      end

      def data
        site.data
      end

      def gumdrop_version
        ::Gumdrop::VERSION
      end
      
    end
  end
  
  class << self

    def view_helpers(&block)
      Util::ViewHelpers.class_eval &block
    end

  end
end
