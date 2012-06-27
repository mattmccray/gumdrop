require 'pathname'

module Gumdrop

  DEFAULT_OPTIONS= {
    relative_paths: true,
    relative_paths_for: ['.html', '.htm', '.php'],
    proxy_enabled: false,
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

    extend Callbacks

    callbacks :on_start, 
              :on_before_scan,
              :on_scan, 
              :on_before_generate,
              :on_generate, 
              :on_before_render,
              :on_render, 
              :on_end

    def initialize(sitefile, opts={})
      @sitefile  = File.expand_path sitefile
      @root_path = File.dirname @sitefile
      @opts      = opts
      @last_run  = nil
      reset_all()
    end

    def contents(*args)
      opts= args.extract_options!
      pattern= args[0] || nil
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

    def rescan
      on_start(self)
      reset_all()
      scan()
      @last_run= Time.now
      # TODO: should on_before_render and on_render be called for rescan()?
      on_end(self)
      self
    end

    def build
      on_start(self)
      scan()
      render()
      @last_run= Time.now
      on_end(self)
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

    # Match a path using a glob-like file pattern
    def path_match(path, pattern)
      File.fnmatch pattern, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_CASEFOLD
    end

  private

    def scan
      build_tree()
      run_generators()
      self
    end


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

      clear_on_start()
      clear_on_before_scan()
      clear_on_scan()
      clear_on_before_generate()
      clear_on_generate()
      clear_on_before_render()
      clear_on_render()
      clear_on_end()

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
        target= if @opts[:quiet] or @opts[:quiet_given]
          nil
        else
          STDOUT
        end
        @log = Logger.new target
        report "Using STDOUT for logging because of exception: #{ $! }" unless target.nil?
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
      dsl = Sitefile.new self
      dsl.instance_eval source
      dsl
    end

    def build_tree
      report "[Scanning from #{src_path}]", :info
      on_before_scan(self)
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
            report " excluding: #{path}", :info
          else
            node.ignore greylist.any? {|pattern| path_match path, pattern }
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
      on_scan(self)
    end

    def run_generators
      report "[Executing Generators]", :info
      on_before_generate(self)
      generators.each_pair do |path, generator|
        generator.execute()
      end
      on_generate(self)
    end

    def render
      unless opts[:dry_run]
        report "[Compiling to #{@out_path}]", :info
        on_before_render(self)
        @node_tree.keys.sort.each do |path|
          node= @node_tree[path]
          unless node.ignore?
            output_path= File.join(@out_path, node.to_s)
            FileUtils.mkdir_p File.dirname(output_path)
            node.renderTo render_context, output_path, content_filters
          else
            report "  ignoring: #{node.to_s}", :info
          end
        end
        on_render(self)
      end
    end

  end

  class Sitefile

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
    
    # Callbacks
    def on_start(&block)
      @site.on_start &block
    end
    def on_before_scan(&block)
      @site.on_before_scan &block
    end
    def on_scan(&block)
      @site.on_scan &block
    end
    def on_before_generate(&block)
      @site.on_before_generate &block
    end
    def on_generate(&block)
      @site.on_generate &block
    end
    def on_before_render(&block)
      @site.on_before_render &block
    end
    def on_render(&block)
      @site.on_render &block
    end
    def on_end(&block)
      @site.on_end &block
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