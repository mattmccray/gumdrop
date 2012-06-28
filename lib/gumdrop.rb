# coding: utf-8

require 'tilt'
require 'fileutils'
require 'active_support/all'

module Gumdrop

  autoload :Context,     "gumdrop/context"
  autoload :Content,     "gumdrop/content"
  autoload :DataManager, "gumdrop/data_manager"
  autoload :Generator,   "gumdrop/generator"
  autoload :HashObject,  "gumdrop/hash_object"
  autoload :Pager,       "gumdrop/data_manager"
  autoload :Server,      "gumdrop/server"
  autoload :VERSION,     "gumdrop/version"
  autoload :ViewHelpers, "gumdrop/view_helpers"

  module CLI
    autoload :External,  "gumdrop/cli/external"    
    autoload :Internal,  "gumdrop/cli/internal"    
  end

  module Support
    autoload :BasePackager, "gumdrop/support/base_packager"    
    autoload :Callbacks,    "gumdrop/support/callbacks"
    autoload :Stitch,       "gumdrop/support/stitch"    
    autoload :Sprockets,    "gumdrop/support/sprockets"    
  end
  
  class << self

    def run(opts={})
      site= fetch_site opts
      unless site.nil?
        old= Dir.pwd
        Dir.chdir site.root_path
  
        site.build
        
        Dir.chdir old
  
        puts "Done." unless opts[:quiet]

      else
        puts "Not in a valid Gumdrop site directory."
      end
    end

    def in_site_folder?(filename="Gumdrop")
      !fetch_site_file(filename).nil?
    end

    def fetch_site(opts={}, prefer_existing=true)
      if defined?(SITE) and prefer_existing
        SITE.opts= opts unless opts.empty?
        SITE
      else
        site_file= Gumdrop.fetch_site_file
        unless site_file.nil?
          Site.new site_file, opts
        else
          nil
        end
      end
    end

    def fetch_site_file(filename="Gumdrop")
      here= Dir.pwd
      found= File.file? File.join( here, filename )
      # TODO: Should be smarter -- This is a hack for Windows support "C:\"
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

    def site_dirname(filename="Gumdrop")
      File.dirname( fetch_site_file( filename ) )
    end

    def change_log
      here= File.dirname(__FILE__)
      File.read File.join(here, "../ChangeLog.md")
    end

  end
  
end

require 'gumdrop/site'
