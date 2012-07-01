module Gumdrop
  
  module Util
    module ViewHelpers
      
      def hidden(&block)
        #no-op
      end
      
      def markdown(source)
        m= Tilt['markdown'].new { source }
        m.render
      end
      
      def textile(source)
        m= Tilt['textile'].new { source }
        m.render
      end
      
      def config
        site.config
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
