
module Gumdrop

  module Utils

    def self.content_hash(base_path)
      Hash.new do |hash, key| 
        templates= Dir["#{base_path}#{key}*"]
        if templates.length > 0
          Content.new( templates[0] )
        else
          puts "NOT FOUND: #{key}"
          nil
        end
      end
    end

  end

end