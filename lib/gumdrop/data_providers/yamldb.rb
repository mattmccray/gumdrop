module Gumdrop::Data
  class YAMLDBDataProvider < YAMLandJSONDataProvider

    extension :yamldb


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
