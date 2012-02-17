
module Gumdrop

  class Build
    attr_reader :root, :src, :opts

    SKIP= %w(.DS_Store .gitignore .git .svn .sass-cache)

    def initialize(root, src, opts={})
      @root= root
      @root_path= root.split('/')
      @src= src
      @opts= opts
      # if opts[:auto_run]
      #   run()
      # end
    end

    def build_tree
      # Scan Filesystem
      #puts "Running in: #{root}"
      Dir.glob("#{src}/**/*", File::FNM_DOTMATCH).each do |path|
        unless File.directory? path or Build::SKIP.include?( File.basename(path) )
          file_path = (path.split('/') - @root_path).join '/'
          node= Content.new(file_path)
          path= node.to_s

          # Sort out Layouts, Generators, and Partials
          if File.extname(path) == ".template"
            Gumdrop.layouts[File.basename(path)]= node

          elsif File.extname(path) == ".generator"
            Gumdrop.generators[File.basename(path)]= Generator.new( node )

          elsif File.basename(path).starts_with?("_")
            partial_name= File.basename(path)[1..-1].gsub(File.extname(File.basename(path)), '')
            # puts "Creating partial #{partial_name} from #{path}"
            Gumdrop.partials[partial_name]= node
          
          else
            Gumdrop.site[path]= node
          end
        end
      end
      
    end

    def run_generators
      Gumdrop.generators.each_pair do |path, generator|
        generator.execute()
      end
    end

    def filter_tree
      Gumdrop.blacklist.each do |skip_path|
        Gumdrop.site.keys.each do |source_path|
          if source_path.starts_with? skip_path
            Gumdrop.report " -ignoring: #{source_path}", :info
            Gumdrop.site.delete source_path
          end
        end
      end
    end

    def render
      unless opts[:dry_run]
        output_base_path= File.expand_path(Gumdrop.config.output_dir)
        Gumdrop.report "[Compiling to #{output_base_path}]", :info
        Gumdrop.site.keys.sort.each do |path|
          node= Gumdrop.site[path]
          output_path= File.join(output_base_path, node.to_s)
          FileUtils.mkdir_p File.dirname(output_path)
          node.renderTo output_path, Gumdrop.content_filters
        end
      end
    end

    def run
      build_tree()
      run_generators()
      filter_tree()
      render()
      self
    end

    class << self
      def run(root, src, opts={})
        new(root, src, opts).run()
      end
    end
  end

end