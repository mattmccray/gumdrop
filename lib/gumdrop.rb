require 'tilt'
require 'fileutils'
require 'active_support/all'

DEFAULT_OPTIONS= {
  :cache_data => false,
  :relative_paths => true,
  :auto_run => false,
  :force_reload => false,
  :root => "."
}

module Gumdrop
  
  autoload :Context, "gumdrop/context"
  autoload :Content, "gumdrop/content"
  autoload :DeferredLoader, "gumdrop/deferred_loader"
  autoload :Generator, "gumdrop/generator"
  autoload :GeneratedrContent, "gumdrop/generator"
  autoload :GenerationDSL, "gumdrop/generator"
  autoload :HashObject, "gumdrop/hash_object"
  autoload :Pager, "gumdrop/pager"
  autoload :Server, "gumdrop/server"
  autoload :Utils, "gumdrop/utils"
  autoload :VERSION, "gumdrop/version"
  autoload :ViewHelpers, "gumdrop/view_helpers"
  
  class << self
    
    attr_accessor :root_path, :source_path, :site, :layouts, :generators, :partials, :config, :data, :content_filters
    
    def run(opts={})
      # Opts
      Gumdrop.config.merge! opts
      
      root= File.expand_path Gumdrop.config.root
      src= File.join root, 'source'
      $: << "#{root}/lib"
      if File.exists? "#{root}/lib/view_helpers.rb"
        # In server mode, we want to reload it every time... right?
        load "#{root}/lib/view_helpers.rb"
        #require 'view_helpers'
      end

      @site        = Hash.new {|h,k| h[k]= nil }
      @layouts     = Hash.new {|h,k| h[k]= nil }
      @generators  = Hash.new {|h,k| h[k]= nil }
      @partials    = Hash.new {|h,k| h[k]= nil }
      @root_path   = root.split '/'
      @source_path = src.split '/'
      @data        = Gumdrop::DeferredLoader.new()

      @content_filters= []
      
      if File.exists? "#{root}/lib/site.rb"
        # In server mode, we want to reload it every time... right?
        source= IO.readlines("#{root}/lib/site.rb").join('')
        GenerationDSL.class_eval source
        #load "#{root}/lib/site.rb" 
        # require 'site' 
      end
      
      # Scan
      #puts "Running in: #{root}"
      Dir.glob("#{src}/**/*", File::FNM_DOTMATCH).each do |path|
        unless File.directory? path or File.basename(path) == '.DS_Store' # should be smarter about this?
          file_path = (path.split('/') - @root_path).join '/'
          node= Content.new(file_path)
          @site[node.to_s]= node
        end
      end
      
      # Layouts, Generators, and Partials
      @site.keys.each do |path|
        if File.extname(path) == ".template"
          @layouts[File.basename(path)]= @site.delete(path)

        elsif File.extname(path) == ".generator"
          @generators[File.basename(path)]= Generator.new( @site.delete(path) )

        elsif File.basename(path).starts_with?("_")
          partial_name= File.basename(path)[1..-1].gsub(File.extname(File.basename(path)), '')
          # puts "Creating partial #{partial_name} from #{path}"
          @partials[partial_name]= @site.delete(path)
        end
      end
      
      @generators.each_pair do |path, generator|
        generator.execute()
      end
      
      
      # Render
      unless opts[:dry_run]
        site.keys.sort.each do |path|
          node= site[path]
          output_path= "output/#{node.to_s}"
          FileUtils.mkdir_p File.dirname(output_path)
          node.renderTo output_path, @content_filters
        end
        puts "Done."
      end
      
    end

  end

  Gumdrop.config= Gumdrop::HashObject.new(DEFAULT_OPTIONS)
  
end