module Gumdrop
  
  module ViewHelpers
    
    # Handy for hiding a block of unfinished code
    # def hidden(&block)
    #   #no-op
    # end
    
    def gumdrop_version
      ::Gumdrop::VERSION
    end
    
  end
  
end