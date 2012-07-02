module Gumdrop::Data
  class YAMLDBDataProvider < Provider

    extension :yamldb

    def available?
      require 'yaml'
      true
    rescue
      false
    end

    def data_for(filepath)
      docs=[]
      File.open(filepath, 'r') do |f|
        YAML.load_documents(f) do |doc|
          docs << to_open_structs( doc ) #unless doc.has_key?("__proto__")
        end
      end
      docs
    end

  end
end
