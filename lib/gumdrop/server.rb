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
    
    if Gumdrop.config.proxy_enabled
      require 'gumdrop/proxy_handler'
      Gumdrop.report 'Enabled proxy at /-proxy/*', :info
      get '/-proxy/*' do
        proxy_to= params[:splat][0]
        proxy_parts= proxy_to.split('/')
        host= proxy_parts.shift
        path_info= "/#{proxy_parts.join('/')}"
        #puts "HOST: #{host}  PATH_INFO: #{path_info}"
        opts={ :to=>host, :path_info=>path_info  }
        Gumdrop.handle_proxy opts, proxy_to, env
      end
      post '/-proxy/*' do
        proxy_to= params[:splat][0]
        proxy_parts= proxy_to.split('/')
        host= proxy_parts.shift
        path_info= "/#{proxy_parts.join('/')}"
        #puts "HOST: #{host}  PATH_INFO: #{path_info}"
        opts={ :to=>host, :path_info=>path_info  }
        Gumdrop.handle_proxy opts, proxy_to, env
      end
      delete '/-proxy/*' do
        proxy_to= params[:splat][0]
        proxy_parts= proxy_to.split('/')
        host= proxy_parts.shift
        path_info= "/#{proxy_parts.join('/')}"
        #puts "HOST: #{host}  PATH_INFO: #{path_info}"
        opts={ :to=>host, :path_info=>path_info  }
        Gumdrop.handle_proxy opts, proxy_to, env
      end
      put '/-proxy/*' do
        proxy_to= params[:splat][0]
        proxy_parts= proxy_to.split('/')
        host= proxy_parts.shift
        path_info= "/#{proxy_parts.join('/')}"
        #puts "HOST: #{host}  PATH_INFO: #{path_info}"
        opts={ :to=>host, :path_info=>path_info  }
        Gumdrop.handle_proxy opts, proxy_to, env
      end
      
    end

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
        # uri_path= params[:splat].join('/')
        # puts "LOOKING FOR: #{uri_path}"
        # if uri_path =~ /^\-proxy\/(.*)$/
        #   uri= URI.parse "http://#{$1}"
        #   
        #   puts "PROXY TO: #{uri}"
        #   
        #   http = Net::HTTP.new(uri.host, uri.port)
        #   response = http.request(Net::HTTP::Get.new(uri.request_uri))
        #   
        #   #[response.code, response.body]
        #    #halt response.code, {}, response.body.to_s
        #    puts "Responded with: #{response.body.to_s}"
        #    #response
        #    [response.code.to_i, {}, response.body.to_s]
        # else
          Gumdrop.log.error "[#{$$}]  *Missing: #{file_path}"
          puts "NOT FOUND: #{file_path}"
          "#{file_path} Not Found"
        # end
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
      #Gumdrop.run dry_run:true 
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
