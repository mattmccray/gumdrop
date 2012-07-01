
# Maybe use Gserver?

require 'sinatra/base'

module Gumdrop

  STATIC_ASSETS= %w(.jpg .jpe .jpeg .gif .ico .png .swf)

  class Server < Sinatra::Base
    include Util::Loggable

    site= Gumdrop.site

    unless site.nil?
      site.rescan()

      set :port, site.config.server_port if site.config.server_port
      
      if site.config.proxy_enabled
        require 'gumdrop/server/proxy_handler'
        get     '/-proxy/*' do handle_proxy(params, env) end
        post    '/-proxy/*' do handle_proxy(params, env) end
        put     '/-proxy/*' do handle_proxy(params, env) end
        delete  '/-proxy/*' do handle_proxy(params, env) end
        patch   '/-proxy/*' do handle_proxy(params, env) end
        options '/-proxy/*' do handle_proxy(params, env) end
        log.info 'Enabled proxy at /-proxy/*'
      end

      get '/*' do
        # log.info "- - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

        file_path= get_content_path params[:splat].join('/'), site
        log.info "\n\n[#{$$}] GET /#{params[:splat].join('/')} -> #{file_path}"
        
        unless static_asset file_path
          since_last_build= Time.now.to_i - site.last_run.to_i
          # site.report "!>!>>>>> since_last_build: #{since_last_build}"
          if since_last_build > site.config.server_timeout
            log.info "[#{$$}] Rebuilding from Source (#{since_last_build} > #{site.config.server_timeout})"
            site.rescan()
          end
        end
        
        if site.content_hash.has_key? file_path
          content= site.content_hash[file_path]
          if content.useLayout?
            log.info "[#{$$}]  *Dynamic: #{file_path} (#{content.ext})"
            content_type :css if content.ext == '.css' # Meh?
            content_type :js if content.ext == '.js' # Meh?
            content_type :xml if content.ext == '.xml' # Meh?
            output= content.render 
            site.content_filters.each {|f| output= f.call(output, content) }
            output
          else
            log.info "[#{$$}]  *Static: #{file_path}"
            send_file site.src_path / file_path
          end
        
        elsif File.exists? site.config.output_dir / file_path
            log.info "[#{$$}]  *Static (from OUTPUT): #{file_path}"
            send_file site.config.output_dir / file_path
        
        else
          log.warning "[#{$$}]  *Missing: #{file_path}", :error
          "#{file_path} Not Found"
        end
      end      

      def get_content_path(file_path, site)
        keys= [
          file_path,
          "#{file_path}.html",
          "#{file_path}/index.html"
        ]
        if file_path == ""
          "index.html"
        else
          keys.detect {|k| site.content_hash.has_key?(k) } or file_path
        end
      end

      def handle_proxy(params, env)
        proxy_to= params[:splat][0]
        proxy_parts= proxy_to.split('/')
        host= proxy_parts.shift
        path_info= "/#{proxy_parts.join('/')}"
        #puts "HOST: #{host}  PATH_INFO: #{path_info}"
        opts={ :to=>host, :path_info=>path_info  }
        Gumdrop.handle_proxy opts, proxy_to, env
      end
      
      def static_asset(file_path)
        return false if file_path.nil? or File.extname(file_path).nil?
        STATIC_ASSETS.include? File.extname(file_path).to_s
      end
      
      run!
    else
      puts "Not in a valid Gumdrop site directory."
    end
  end
end