module Gumdrop::Data
  class YAMLDBDataProvider < Provider

    extension :yamldb

    def available?
      require 'yaml'
      true
    rescue LoadError
      false
    end

    def data_for(filepath)
      docs=[]
      File.open(filepath, 'r') do |f|
        YAML.load_documents(f) do |doc|
          docs << supply_data( doc ) #unless doc.has_key?("__proto__")
        end
      end
      docs
    end

  end
end
