# coding: utf-8

require 'tilt'
require 'fileutils'
require 'active_support/all'

module Gumdrop

  autoload :Callbacks, "gumdrop/callbacks"
  autoload :Context, "gumdrop/context"
  autoload :Content, "gumdrop/content"
  autoload :DataManager, "gumdrop/data_manager"
  autoload :Generator, "gumdrop/generator"
  autoload :HashObject, "gumdrop/hash_object"
  autoload :Pager, "gumdrop/data_manager"
  autoload :Server, "gumdrop/server"
  autoload :VERSION, "gumdrop/version"
  autoload :ViewHelpers, "gumdrop/view_helpers"
  
  class << self

    def run(opts={})
      site_file= Gumdrop.fetch_site_file
      unless site_file.nil?
        site= Site.new site_file, opts

        old= Dir.pwd
        Dir.chdir site.root_path

        site.build
        
        Dir.chdir old

        puts "Done."
      else
        puts "Not in a valid Gumdrop site directory."
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

    def site_dirname(filename="Gumdrop")
      File.dirname( fetch_site_file( filename ) )
    end

  end
  
end

require 'gumdrop/site'
