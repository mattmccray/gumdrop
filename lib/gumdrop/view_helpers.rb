module Gumdrop
  
  module ViewHelpers
    
    def hidden(&block)
      #no-op
    end
    
    def markdown(source)
      m= Tilt['markdown'].new { source }
      m.render
    end
    
    
    def gumdrop_version
      ::Gumdrop::VERSION
    end
    
  end
  
end