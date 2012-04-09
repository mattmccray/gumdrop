require 'pathname'

module Gumdrop

  DEFAULT_OPTIONS= {
    relative_paths: true,
    proxy_enabled: true,
    output_dir: "./output",
    source_dir: "./source",
    data_dir: './data',
    log: './logs/build.log',
    ignore: %w(.DS_Store .gitignore .git .svn .sass-cache),
    server_timeout: 15,
    # server_port: 4567,
    env: 'production'
  }

  class Site
    
    attr_reader :opts,
                :root_path, 
                :src_path,
                :blacklist,
                :greylist,
                :redirects,
                :content_filters,
                :layouts,
                :partials,
                :generators,
                :config,
                :data,
                :sitefile,
                :node_tree,
                :last_run
    

    def initialize(sitefile, opts={})
      @sitefile  = File.expand_path sitefile
      @root_path = File.dirname @sitefile
      @opts      = opts
      @last_run  = nil
      reset_all()
    end

    def contents(pattern=nil, opts={})
      if pattern.nil?
        if opts[:as] == :hash
          @node_tree
        else
          @node_tree.values
        end
      else
        nodes = opts[:as] == :hash ? {} : []
        @node_tree.keys.each do |path|
          if path_match path, pattern
            if opts[:as] == :hash
              nodes[path]= @node_tree[path]
            else
              nodes << @node_tree[path]
            end
          end
        end
        nodes
      end
    end

    def scan
      build_tree()
      run_generators()
      @last_run= Time.now
      self
    end

    def rescan
      reset_all()
      scan()
      @last_run= Time.now
      self
    end

    def build
      scan()
      render()
      @last_run= Time.now
      self
    end

    def report(msg, level=:info)
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

    # FIXME: Should a new Context be created for every page? For now
    #        it's a single context for whole site
    def render_context
      @context ||= Context.new self
      @context
    end


  private

    def reset_all
      @content_filters = []
      @blacklist       = []
      @greylist        = []
      @redirects       = []

      @node_tree       = Hash.new {|h,k| h[k]= nil }
      @layouts         = Hash.new {|h,k| h[k]= nil }
      @partials        = Hash.new {|h,k| h[k]= nil }
      @generators      = Hash.new {|h,k| h[k]= nil }
      
      @config          = Gumdrop::Config.new DEFAULT_OPTIONS

      load_sitefile()
      
      @data_path       = get_expanded_path(@config.data_dir)
      @src_path        = get_expanded_path(@config.source_dir)
      @out_path        = get_expanded_path(@config.output_dir)

      @data            = Gumdrop::DataManager.new self, @data_path

      init_logging()
    end

    def init_logging
      begin
        @log = Logger.new @config.log, 'daily'
      rescue
        @log = Logger.new STDOUT
      end
      @log.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime}: #{msg}\n"
      end
    end

    def get_expanded_path(path)
      if (Pathname.new path).absolute?
        path
      else
        File.expand_path File.join(@root_path, path)
      end
    end

    def load_sitefile
      source= File.read( @sitefile )
      dsl = SitefileDSL.new self
      dsl.instance_eval source
      dsl
    end

    def build_tree
      report "[Scanning from #{src_path}]", :info
      # Report blacklists and greylists
      blacklist.each do |path|
        report " blacklist: #{path}", :info
      end
      greylist.each do |path|
        report "  greylist: #{path}", :info
      end

      # Scan Filesystem
      Dir.glob("#{src_path}/**/*", File::FNM_DOTMATCH).each do |path|
        unless File.directory? path or @config.ignore.include?( File.basename(path) )
          node= Content.new(path, self)
          path= node.to_s
          if blacklist.any? {|pattern| path_match path, pattern }
            report "-excluding: #{path}", :info
          else
            node.ignored= greylist.any? {|pattern| path_match path, pattern }
            # Sort out Layouts, Generators, and Partials
            if File.extname(path) == ".template"
              layouts[path]= node
              layouts[File.basename(path)]= node

            elsif File.extname(path) == ".generator"
              generators[File.basename(path)]= Generator.new( node, self )

            elsif File.basename(path).starts_with?("_")
              partial_name= File.basename(path)[1..-1].gsub(File.extname(File.basename(path)), '')
              partial_node_path= File.join File.dirname(path), partial_name
              # puts "Creating partial #{partial_name} from #{path}"
              partials[partial_name]= node
              partials[partial_node_path]= node
            
            else
              @node_tree[path]= node
            end
          end
        end
      end
    end

    def run_generators
      report "[Executing Generators]", :info
      generators.each_pair do |path, generator|
        generator.execute()
      end
    end

    def render
      unless opts[:dry_run]
        report "[Compiling to #{@out_path}]", :info
        @node_tree.keys.sort.each do |path|
          node= @node_tree[path]
          unless node.ignored 
            output_path= File.join(@out_path, node.to_s)
            FileUtils.mkdir_p File.dirname(output_path)
            node.renderTo render_context, output_path, content_filters
          else
            report " -ignoring: #{node.to_s}", :info
          end
        end
      end
    end

    # Match a path using a glob-like file pattern
    def path_match(path, pattern)
      File.fnmatch pattern, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_CASEFOLD
    end
  end

  class SitefileDSL

    def initialize(site)
      @site= site
    end
  
    def generate(&block)
      # Auto-generated, numerical, key for a site-level generator
      @site.generators[@site.generators.keys.length] = Generator.new(block, @site)
    end
  
    def content_filter(&block)
      @site.content_filters << block
    end
  
    def skip(path)
      @site.blacklist << path
    end
    alias_method :blacklist, :skip

    def ignore(path)
      @site.greylist << path
    end
    alias_method :greylist, :ignore
    alias_method :graylist, :ignore

    def view_helpers(&block)
      Gumdrop::ViewHelpers.class_eval &block
    end

    def configure(&block)
      if block.arity > 0
        block.call @site.config
      else
        @site.config.instance_eval &block
      end
    end
  
  end

  class Config < HashObject
    
    def set(key, value)
      self[key]= value
    end
    def get(key)
      self[key]
    end

  end

end