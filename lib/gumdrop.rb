require 'tilt'
require 'fileutils'
require 'active_support/all'

DEFAULT_OPTIONS= {
  :cache_data => false,
  :relative_paths => true,
  :auto_run => false,
  :root => "."
}

module Gumdrop
  
  autoload :Context, "gumdrop/context"
  autoload :Content, "gumdrop/content"
  autoload :Generator, "gumdrop/generator"
  autoload :HashObject, "gumdrop/hash_object"
  autoload :Server, "gumdrop/server"
  autoload :Utils, "gumdrop/utils"
  autoload :VERSION, "gumdrop/version"
  autoload :ViewHelpers, "gumdrop/view_helpers"
  
  class << self
    
    attr_accessor :root_path, :source_path, :site, :layouts, :generators, :partials, :config
    
    def run(opts={})
      # Opts
      Gumdrop.config.merge! opts
      
      root= File.expand_path Gumdrop.config.root
      src= File.join root, 'source'
      if File.exists? "#{root}/lib/view_helpers.rb"
        $: << "#{root}/lib"
        require 'view_helpers'
      end

      @site        = Hash.new {|h,k| h[k]= nil }
      @layouts     = Hash.new {|h,k| h[k]= nil }
      @generators  = Hash.new {|h,k| h[k]= nil }
      @partials    = Hash.new {|h,k| h[k]= nil }
      @root_path   = root.split '/'
      @source_path = src.split '/'
      
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
          @generators[File.basename(path)]= @site.delete(path)

        elsif File.basename(path).starts_with?("_")
          partial_name= File.basename(path)[1..-1].gsub(File.extname(File.basename(path)), '')
          # puts "Creating partial #{partial_name} from #{path}"
          @partials[partial_name]= @site.delete(path)
        end
      end
      
      # Render
      site.keys.each do |path|
        node= site[path]
        output_path= "output/#{node.to_s}"
        FileUtils.mkdir_p File.dirname(output_path)
        node.renderTo output_path
      end
      
      puts "Done."
    end
  end

  Gumdrop.config= Gumdrop::HashObject.new(DEFAULT_OPTIONS)
  
end