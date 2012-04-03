
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
      Gumdrop.report "[Scanning from #{src}]", :info
      # Report blacklists and greylists
      Gumdrop.blacklist.each do |path|
        Gumdrop.report " blacklist: #{path}", :info
      end
      Gumdrop.greylist.each do |path|
        Gumdrop.report "  greylist: #{path}", :info
      end

      # Scan Filesystem
      #puts "Running in: #{root}"
      Dir.glob("#{src}/**/*", File::FNM_DOTMATCH).each do |path|
        unless File.directory? path or Build::SKIP.include?( File.basename(path) )
          file_path = (path.split('/') - @root_path).join '/'
          node= Content.new(file_path)
          path= node.to_s

          # Sort out Layouts, Generators, and Partials
          if File.extname(path) == ".template"
            Gumdrop.layouts[path]= node
            Gumdrop.layouts[File.basename(path)]= node

          elsif File.extname(path) == ".generator"
            Gumdrop.generators[File.basename(path)]= Generator.new( node )

          elsif File.basename(path).starts_with?("_")
            partial_name= File.basename(path)[1..-1].gsub(File.extname(File.basename(path)), '')
            partial_node_path= File.join File.dirname(path), partial_name
            # puts "Creating partial #{partial_name} from #{path}"
            Gumdrop.partials[partial_name]= node
            Gumdrop.partials[partial_node_path]= node
          else
            Gumdrop.site[path]= node
          end
        end
      end
      
    end

    def run_generators
      Gumdrop.report "[Executing Generators]", :info
      Gumdrop.generators.each_pair do |path, generator|
        generator.execute()
      end
    end

    # Expunge blacklisted files
    def filter_tree
      Gumdrop.blacklist.each do |blacklist_pattern|
        Gumdrop.site.keys.each do |source_path|
          if path_match source_path, blacklist_pattern
            Gumdrop.report "-excluding: #{source_path}", :info
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
          unless Gumdrop.greylist.any? {|pattern| path_match path, pattern }
            node= Gumdrop.site[path]
            output_path= File.join(output_base_path, node.to_s)
            FileUtils.mkdir_p File.dirname(output_path)
            node.renderTo output_path, Gumdrop.content_filters
          else
            Gumdrop.report " -ignoring: #{path}", :info
          end
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

    # Match a path using a glob-like file pattern
    def path_match(path, pattern)
      File.fnmatch pattern, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_CASEFOLD
    end


    class << self
      def run(root, src, opts={})
        new(root, src, opts).run()
      end
    end
  end

end