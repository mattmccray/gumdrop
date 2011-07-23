module Gumdrop
  
  module Server
    
    class << self
    
      def start(opts={})
        # Opts
        opts.reverse_merge! :auto_run => true, :cache_data => false
        Gumdrop.config.merge! opts

        require 'sinatra'

        set :port, Gumdrop.config.port if Gumdrop.config.port
        
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
        
        if Gumdrop.config.auto_run
          Sinatra::Application.run!
        else
          Sinatra::Application
        end
      end
    
    end
    
    
  end
  
end