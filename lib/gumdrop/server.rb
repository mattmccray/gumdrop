# Rework this to be nicer.. Extend Sintra::Base?

require 'sinatra/base'
require 'logger'

module Gumdrop

  STATIC_ASSETS= %w(.jpg .jpe .jpeg .gif .ico .png .swf)

  class Server < Sinatra::Base
    site_file= Gumdrop.fetch_site_file
    unless site_file.nil?
      site= Site.new site_file
      site.rescan()

      set :port, site.config.server_port if site.config.server_port
      
      if site.config.proxy_enabled
        require 'gumdrop/proxy_handler'
        get     '/-proxy/*' do handle_proxy(params, env) end
        post    '/-proxy/*' do handle_proxy(params, env) end
        put     '/-proxy/*' do handle_proxy(params, env) end
        delete  '/-proxy/*' do handle_proxy(params, env) end
        patch   '/-proxy/*' do handle_proxy(params, env) end
        options '/-proxy/*' do handle_proxy(params, env) end
        site.report 'Enabled proxy at /-proxy/*', :info
      end

      get '/*' do
        site.report "- - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

        file_path= get_content_path params[:splat].join('/'), site
        site.report "[#{$$}] GET /#{params[:splat].join('/')} -> #{file_path}"
        
        unless static_asset file_path
          since_last_build= Time.now.to_i - site.last_run.to_i
          # site.report "!>!>>>>> since_last_build: #{since_last_build}"
          if since_last_build > site.config.server_timeout
            site.report "[#{$$}] Rebuilding from Source (#{since_last_build} > #{site.config.server_timeout})"
            site.rescan()
          end
        end
        
        if site.content_hash.has_key? file_path
          content= site.content_hash[file_path]
          if content.useLayout?
            site.report "[#{$$}]  *Dynamic: #{file_path} (#{content.ext})"
            content_type :css if content.ext == '.css' # Meh?
            content_type :js if content.ext == '.js' # Meh?
            content_type :xml if content.ext == '.xml' # Meh?
            output= content.render 
            site.content_filters.each {|f| output= f.call(output, content) }
            output
          else
            site.report "[#{$$}]  *Static: #{file_path}"
            send_file File.join( site.src_path, file_path)
          end
        
        elsif File.exists? File.join(site.config.output_dir, file_path)
            site.report "[#{$$}]  *Static (from OUTPUT): #{file_path}"
            send_file File.join(site.config.output_dir, file_path)
        
        else
          site.report "[#{$$}]  *Missing: #{file_path}", :error
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