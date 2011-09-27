require 'tilt'
require 'fileutils'
require 'active_support/all'

DEFAULT_OPTIONS= {
  :cache_data => false,
  :relative_paths => true,
  :auto_run => false,
  :force_reload => false,
  :root => ".",
  :log_level => :info,
  :output_dir => "./output"
}

LOG_LEVELS = {
  :info => 0,
  :warning => 1,
  :error => 2
}

# LOG_LEVELS = {
#   info: 0,
#   warning: 1,
#   error: 2
# }

module Gumdrop
  
  autoload :Context, "gumdrop/context"
  autoload :Content, "gumdrop/content"
  autoload :DeferredLoader, "gumdrop/deferred_loader"
  autoload :DSL, "gumdrop/dsl"
  autoload :Generator, "gumdrop/generator"
  autoload :GeneratedrContent, "gumdrop/generator"
  autoload :HashObject, "gumdrop/hash_object"
  autoload :Pager, "gumdrop/pager"
  autoload :Server, "gumdrop/server"
  autoload :Utils, "gumdrop/utils"
  autoload :VERSION, "gumdrop/version"
  autoload :ViewHelpers, "gumdrop/view_helpers"
  
  class << self
    
    attr_accessor :root_path, :source_path, :site, :layouts, :generators, :partials, :config, :data, :content_filters, :blacklist
    
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

      @content_filters= []
      @blacklist      = []
      
      if File.exists? "#{root}/lib/site.rb"
        # In server mode, we want to reload it every time... right?
        source= IO.readlines("#{root}/lib/site.rb").join('')
        DSL.class_eval source
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
      
      @blacklist.each do |skip_path|
        @site.keys.each do |source_path|
          if source_path.starts_with? skip_path
            Gumdrop.report " -ignoring: #{source_path}", :info
            @site.delete source_path
          end
        end
      end
      
      # Render
      unless opts[:dry_run]
        output_base_path= File.expand_path(Gumdrop.config.output_dir)
        site.keys.sort.each do |path|
          #unless @blacklist.detect {|p| path.starts_with?(p) }
            node= site[path]
            output_path= File.join(output_base_path, node.to_s)
            FileUtils.mkdir_p File.dirname(output_path)
            node.renderTo output_path, @content_filters
          # else
          #   Gumdrop.report " -ignoring: #{path}", :info
          # end
        end
        puts "Done."
      end
      
    end

    # levels: info, warning, error
    def report(msg, level=:info)
      ll= Gumdrop.config.log_level
      case level
      when :info
        puts msg if ll == :info
      when :warning
        puts msg if ll == :info or ll == :warning
      else
        puts msg
      end
    end
  end

  Gumdrop.config= Gumdrop::HashObject.new(DEFAULT_OPTIONS)
  
end