module Gumdrop::Data
  class CSVDataProvider < Provider
    
    extension :csv

    def available?
      require 'csv'
      true
    rescue
      false
    end

    def data_for(filepath)
      supply_data CSV.read(filepath)
    end

  end
end
