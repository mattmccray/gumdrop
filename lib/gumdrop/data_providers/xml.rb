module Gumdrop::Data
  class XMLDataProvider < Provider

    extension :xml

    def available?
      require 'rexml'
      require 'active_support/xml_mini/rexml'
      true
    rescue
      false
    end

    def data_for(filepath)
      to_open_structs ActiveSupport::XmlMini_REXML.parse(File.read(filepath))
    end

  end
end
