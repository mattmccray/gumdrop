# Rework this to be nicer.. Extend Sintra::Base

require 'sinatra/base'

module Gumdrop

  class Server < Sinatra::Base

    set :port, Gumdrop.config.port if Gumdrop.config.port
    
    get '/' do
      redirect '/index.html'
    end
    
    get '/*' do
      file_path= params[:splat].join('/')
      matches= Dir["source/#{file_path}*"] 
      if matches.length > 0
        
        Gumdrop.site= Gumdrop.layouts= Gumdrop.generators= Utils.content_hash("source/**/")
        Gumdrop.partials= Utils.content_hash("source/**/_")
                    
        content= Content.new matches[0]
        if content.useLayout?
          content_type :css if content.ext == '.css' # Meh?
          content_type :js if content.ext == '.js' # Meh?
          content_type :xml if content.ext == '.xml' # Meh?
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
      run!
    end    

    def self.start(opts={})
      # Options
      opts.reverse_merge! :auto_run => true, :cache_data => false
      Gumdrop.config.merge! opts
      ::Gumdrop::Server
    end

  end
    
end