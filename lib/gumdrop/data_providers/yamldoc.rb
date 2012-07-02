module Gumdrop::Data
  class YAMLDocDataProvider < Provider

    extension :yamldoc

    def available?
      require 'yaml'
      true
    rescue
      false
    end

    def data_for(filepath)
      yamldoc= Gumdrop::Util::YamlDoc.new File.read(filepath), true
      to_open_structs yamldoc.data
    end

  end
end
