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
      to_open_structs CSV.read(filepath)
    end

  end
end
