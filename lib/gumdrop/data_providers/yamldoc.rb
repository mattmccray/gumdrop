module Gumdrop::Data
  class YAMLDocDataProvider < Provider

    extension :yamldoc

    def available?
      require 'yaml'
      true
    rescue LoadError
      false
    end

    def data_for(filepath)
      yamldoc= Gumdrop::Util::YamlDoc.new File.read(filepath), true
      supply_data yamldoc.data
    end

  end
end
