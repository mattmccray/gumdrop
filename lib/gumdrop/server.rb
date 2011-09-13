# Rework this to be nicer.. Extend Sintra::Base

require 'sinatra/base'

module Gumdrop

  class Server < Sinatra::Base

    set :port, Gumdrop.config.port if Gumdrop.config.port
    
    # get '/' do
    #   redirect '/index.html'
    # end
    
    Gumdrop.run :dry_run=>true

    get '/*' do
      file_path= get_content_path params[:splat].join('/')
      
      if Gumdrop.config.force_reload
        unless %w(.css .js .jpg .jpe .jpeg .gif .ico .png).include? File.extname(file_path).to_s
          Gumdrop.run :dry_run=>true
        end
      end
      
      if Gumdrop.site.has_key? file_path
        content= Gumdrop.site[file_path]
        if content.useLayout?
          content_type :css if content.ext == '.css' # Meh?
          content_type :js if content.ext == '.js' # Meh?
          content_type :xml if content.ext == '.xml' # Meh?
          content.render
        else
          send_file "source/#{file_path}"
        end
      else
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
      Gumdrop.run :dry_run=>true 
      run!
    end    

    def self.start(opts={})
      # Options
      opts.reverse_merge! :auto_run => true, :cache_data => false
      Gumdrop.config.merge! opts
      Gumdrop.run :dry_run=>true 
      ::Gumdrop::Server
    end

  end
    
end