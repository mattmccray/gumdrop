module Gumdrop::Data
  class YAMLandJSONDataProvider < Provider

    extensions :yaml, :yml, :json

    def available?
      require 'yaml'
      true
    rescue LoadError
      false
    end

    def data_for(filepath)
      supply_data YAML.load_file(filepath)
    end

  end
end
