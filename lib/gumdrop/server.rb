# Rework this to be nicer.. Extend Sintra::Base

require 'sinatra/base'
require 'logger'


module Gumdrop

  class Server < Sinatra::Base

    set :port, Gumdrop.config.port if Gumdrop.config.port


    server_log= 'logs/server.log'
    
    # get '/' do
    #   redirect '/index.html'
    # end
    
    Gumdrop.run dry_run:true, log:server_log

    get '/*' do
      file_path= get_content_path params[:splat].join('/')
      
      Gumdrop.log.info "[#{$$}] GET /#{params[:splat].join('/')}"
      #Gumdrop.log.debug " last built: #{Gumdrop.last_run}"

      
      if Gumdrop.site.has_key? file_path
        content= Gumdrop.site[file_path]
        if content.useLayout?
          # Only do a force_reload if the resource is dynamic!
          if Gumdrop.config.force_reload
            unless %w(.jpg .jpe .jpeg .gif .ico .png).include? File.extname(file_path).to_s
              since_last_build= Time.now.to_i - Gumdrop.last_run.to_i
              if since_last_build > 2
                Gumdrop.log.debug "[#{$$}] !!> REBUILDING"
                Gumdrop.run dry_run:true, log:server_log
              end
            end
          end
          Gumdrop.log.info "[#{$$}]  *Dynamic: #{file_path}"
          content_type :css if content.ext == '.css' # Meh?
          content_type :js if content.ext == '.js' # Meh?
          content_type :xml if content.ext == '.xml' # Meh?
          content.render
        else
          Gumdrop.log.info "[#{$$}]  *Static: #{file_path}"
          source_base_path= File.expand_path(Gumdrop.config.source_dir)
          send_file File.join( source_base_path, file_path)
        end
      else
        Gumdrop.log.error "[#{$$}]  *Missing: #{file_path}"
        puts "NOT FOUND: #{file_path}"
        "#{file_path} Not Found"
      end
    end
    

    def get_content_path(file_path)
      keys= [
        file_path,
        "#{file_path}.html",
        "#{file_path}/index.html"
      ]
      if file_path == ""
        "index.html"
      else
        keys.detect {|k| Gumdrop.site.has_key?(k) }
      end
    end
    
    if Gumdrop.config.auto_run
      Gumdrop.run dry_run:true 
      run!
    end    

    def self.start(opts={})
      # Options
      opts.reverse_merge! auto_run:true, cache_data:false
      Gumdrop.config.merge! opts
      Gumdrop.run dry_run:true, log:server_log
      ::Gumdrop::Server
    end

  end
    
end
