# coding: utf-8

require 'tilt'
require 'fileutils'
require 'active_support/all'

DEFAULT_OPTIONS= {
  cache_data: false,
  relative_paths: true,
  auto_run: false,
  force_reload: false,
  root: ".",
  log_level: :info,
  output_dir: "./output",
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
                  :log,
                  :last_run
    
    def run(opts={})
      # Opts
      Gumdrop.config.merge! opts
      
      root= File.expand_path Gumdrop.config.root
      src= File.join root, 'source'
      $: << "#{root}/lib"
      if File.exists? "#{root}/lib/view_helpers.rb"
        # In server mode, we want to reload it every time... right?
        load "#{root}/lib/view_helpers.rb"
      end

      @site        = Hash.new {|h,k| h[k]= nil }
      @layouts     = Hash.new {|h,k| h[k]= nil }
      @generators  = Hash.new {|h,k| h[k]= nil }
      @partials    = Hash.new {|h,k| h[k]= nil }
      @root_path   = root.split '/'
      @source_path = src.split '/'
      @data        = Gumdrop::DeferredLoader.new()
      @last_run    = Time.now

      begin
        @log         = Logger.new Gumdrop.config.log, 'daily'
      rescue
        @log        = Logger.new STDOUT
      end
      @log.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime}: #{msg}\n"
      end

      @content_filters= []
      @blacklist      = []
      
      if File.exists? "#{root}/lib/site.rb"
        # In server mode, we want to reload it every time... right?
        source= IO.readlines("#{root}/lib/site.rb").join('')
        DSL.class_eval source
      end

      Build.run root, src, opts
      
      puts "Done."
    end

    # levels: info, warning, error
    def report(msg, level=:info)
      ll= Gumdrop.config.log_level
      case level
      when :info
        #puts msg if ll == :info
        @log.info msg
      when :warning
        #puts msg if ll == :info or ll == :warning
        @log.warn msg
      else
        puts msg
        @log.error msg
      end
    end
  end

  Gumdrop.config= Gumdrop::HashObject.new(DEFAULT_OPTIONS)
  
end
