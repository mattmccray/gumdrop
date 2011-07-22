require 'tilt'
require 'fileutils'
require 'active_support/all'

module Gumdrop
  
  class << self
    
    attr_accessor :root_path, :source_path, :site, :layouts
    
    def run(root=".")
      # Opts
      root= File.expand_path root
      src= File.join root, 'source'

      @site= Hash.new {|h,k| h[k]= nil }
      @layouts= Hash.new {|h,k| h[k]= nil }
      @root_path= root.split '/'
      @source_path= src.split '/'
      
      # Scan
      #puts "Running in: #{root}"
      Dir["#{src}/**/*"].each do |path|
        unless File.directory? path
          file_path = (path.split('/') - @root_path).join '/'
          node= Content.new(file_path)
          @site[node.to_s]= node
        end
      end
      
      # Layout
      @site.keys.each do |path|
        if File.extname(path) == ".template"
          @layouts[File.basename(path)]= @site.delete(path)
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
  
end

base= File.dirname(__FILE__)

require "#{base}/gumdrop/version.rb"
require "#{base}/gumdrop/context.rb"
require "#{base}/gumdrop/content.rb"
require "#{base}/gumdrop/server.rb"
require "#{base}/gumdrop/generator.rb"
