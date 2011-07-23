module Gumdrop
  
  module ViewHelpers
    
    # Calculate the years for a copyright
    def copyright_years(start_year, divider="&#8211;")
      end_year = Date.today.year
      if start_year == end_year
        "#{start_year}"
      else
        "#{start_year}#{divider}#{end_year}"
      end
    end

    # Handy for hiding a block of unfinished code
    def hidden(&block)
      #no-op
    end
    
    def gumdrop_version
      ::Gumdrop::VERSION
    end
    
  end
  
end