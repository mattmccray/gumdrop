module Gumdrop::Data
  class YAMLandJSONDataProvider < Provider

    extensions :yaml, :yml, :json

    def available?
      require 'yaml'
      true
    rescue
      false
    end

    def data_for(filepath)
      to_open_structs YAML.load_file(filepath)
    end

  end
end
