module Gumdrop
  
  module Server
    
    class << self
    
      def start(port=8888)
        puts "Serving at http://0.0.0.0:#{port}"
        
        set :port, port
        
        require 'sinatra'
        
        get '/' do
          redirect '/index.html'
        end
        
        get '/*' do
          file_path= params[:splat].join('/')
          matches= Dir["source/#{file_path}*"] 
          if matches.length > 0
            
            Gumdrop.site = Gumdrop.layouts= Hash.new do |hash, key| 
              templates= Dir["source/**/#{key}*"]
              if templates.length > 0
                Content.new( templates[0] )
              else
                puts "NOT FOUND: #{key}"
                nil
              end
            end
                        
            content= Content.new matches[0]
            if content.useLayout?
              content_type :css if content.ext == '.css' # Meh?
              content.render
            else
              send_file matches[0]
            end
          else
            puts "NOT FOUND: #{file_path}"
            "#{file_path} Not Found"
          end
        end
        
        Sinatra::Application.run!
      end
    
    end
    
    
  end
  
end