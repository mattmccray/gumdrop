module Gumdrop::Data
  class XMLDataProvider < Provider

    extension :xml

    def available?
      true
    end

    def data_for(filepath)
      supply_data Hash.from_xml File.read(filepath)
    end

  end
end
