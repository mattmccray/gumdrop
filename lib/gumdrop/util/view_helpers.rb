module Gumdrop
  
  module Util
    module ViewHelpers
      
      def hidden(&block)
        #no-op
      end
      
      def markdown(source)
        eng= Gumdrop::Renderer.for 'markdown'
        unless eng.nil?
          eng.new(source).render
        else
          raise StandardError, "Markdown is not available: Include a Markdown engine in your Gemfile!"
        end
      end
      
      def textile(source)
        eng= Gumdrop::Renderer.for 'textile'
        unless eng.nil?
          eng.new(source).render
        else
          raise StandardError, "Textile is not available: Include a Textile engine in your Gemfile!"
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
