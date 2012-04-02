# coding: utf-8

require 'tilt'
require 'fileutils'
require 'active_support/all'

DEFAULT_OPTIONS= {
  cache_data: false,
  relative_paths: true,
  auto_run: false,
  force_reload: false,
  proxy_enabled: true,
  output_dir: "./output",
  lib_dir: "./lib",
  source_dir: "./source",
  data_dir: './data',
  log_level: :info,
  log: 'logs/build.log'
}

LOG_LEVELS = {
  info: 0,
  warning: 1,
  error: 2
}

module Gumdrop
  
  autoload :Build, "gumdrop/build"
  autoload :Context, "gumdrop/context"
  autoload :Content, "gumdrop/content"
  autoload :DeferredLoader, "gumdrop/deferred_loader"
  autoload :DSL, "gumdrop/dsl"
  autoload :Generator, "gumdrop/generator"
  autoload :GeneratedrContent, "gumdrop/generator"
  autoload :HashObject, "gumdrop/hash_object"
  autoload :Logging, "gumdrop/logging"
  autoload :Pager, "gumdrop/pager"
  autoload :Server, "gumdrop/server"
  autoload :Utils, "gumdrop/utils"
  autoload :VERSION, "gumdrop/version"
  autoload :ViewHelpers, "gumdrop/view_helpers"
  
  class << self
    
    attr_accessor :root_path, 
                  :source_path, 
                  :site, 
                  :layouts, 
                  :generators, 
                  :partials, 
                  :config, 
                  :data, 
                  :content_filters, 
                  :blacklist,
                  :greylist,
                  :log,
                  :last_run
    
    def run(opts={})
      site_file= Gumdrop.fetch_site_file

      unless site_file.nil?
        @generators  = Hash.new {|h,k| h[k]= nil }
        @content_filters= []
        @blacklist      = []
        @greylist       = []

        # In server mode, we want to reload it every time... right?
        source= IO.readlines( site_file ).join('')
        DSL.class_eval source

        Gumdrop.config.merge! opts # These beat those in the Gumdrop file?
        
        root= File.expand_path File.dirname(site_file)
        Dir.chwd root

        src= File.expand_path Gumdrop.config.source_dir #File.join root, 'source'      
        lib_path= File.expand_path Gumdrop.config.lib_dir

        @root_path   = root.split '/'
        @source_path = src.split '/'
        @site        = Hash.new {|h,k| h[k]= nil }
        @layouts     = Hash.new {|h,k| h[k]= nil }
        @partials    = Hash.new {|h,k| h[k]= nil }
        @data        = Gumdrop::DeferredLoader.new( Gumdrop.config.data_dir )
        @last_run    = Time.now

        begin
          @log         = Logger.new Gumdrop.config.log, 'daily'
        rescue
          @log        = Logger.new STDOUT
        end
        @log.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime}: #{msg}\n"
        end

        Build.run root, src, opts
        
        puts "Done."
      
      else
        puts "Not in a valid Gumdrop site directory."

      end
    end

    # levels: info, warning, error
    def report(msg, level=:info)
      ll= Gumdrop.config.log_level
      case level
      when :info
        @log.info msg
      when :warning
        @log.warn msg
      else
        puts msg
        @log.error msg
      end
    end

    def in_site_folder?(filename="Gumdrop")
      !fetch_site_file(filename).nil?
    end

    def fetch_site_file(filename="Gumdrop")
      here= Dir.pwd
      found= File.file? File.join( here, filename )
      while !found and File.directory?(here) and File.dirname(here).length > 3
        here= File.expand_path File.join(here, '../')
        found= File.file? File.join( here, filename )
      end
      if found
        File.expand_path File.join(here, filename)
      else
        nil
      end
    end

  end


  Gumdrop.config= Gumdrop::HashObject.new(DEFAULT_OPTIONS)


  module Configurator
    class << self
      def set(key,value)
        # puts "Setting Gumdrop.config.#{key} = #{value}"
        Gumdrop.config[key.to_sym]= value
      end
    end
  end
  
end
