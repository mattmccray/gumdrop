module Gumdrop::Data
  class YAMLDocDataProvider < YAMLandJSONDataProvider

    extension :yamldoc

    def data_for(filepath)
      yamldoc= Gumdrop::Util::YamlDoc.new File.read(filepath), true
      supply_data yamldoc.data
    end

  end
end
