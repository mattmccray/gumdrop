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

    extend Support::Callbacks
    
    attr_reader :opts,
                :root_path, 
                :src_path,
                :out_path,
                :data_path,
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
                :content_hash,
                :last_run

    callbacks :on_start, 
              :on_before_scan,
              :on_scan, 
              :on_before_generate,
              :on_generate, 
              :on_before_render,
              :on_render,
              :on_before_render_item,
              :on_render_item,
              :on_end

    def initialize(sitefile, opts={})
      @sitefile  = File.expand_path sitefile
      @root_path = File.dirname @sitefile
      @opts      = opts
      @last_run  = nil
      reset_all()
    end

    def opts=(opts={})
      @opts= opts
    end

    def contents(*args)
      opts= args.extract_options!
      pattern= args.first || nil

      if pattern.nil? or pattern.empty?
        if opts[:as] == :hash
          @content_hash
        else
          @content_hash.values
        end
      
      else
        if pattern.is_a? Array
          nodes= opts[:as] == :hash ? {} : []
          pattern.each do |subpattern|
            if opts[:as]== :hash
              nodes.merge! match_nodes(subpattern, opts)
            else
              nodes << match_nodes(subpattern, opts)
            end
          end
          opts[:as]== :hash ? nodes : nodes.flatten
        else
          match_nodes(subpattern, opts)
        end
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

    def build(force_reset=false)
      on_start(self)
      report "[#{ Time.new }]"
      reset_all() if force_reset
      scan()
      render()
      @last_run= Time.now
      on_end(self)
      report "[Done]"
      self
    end
    
    def rebuild
      build true
    end

    def report(msg, level=:info)
      case level
        when :info
          unless @opts[:quiet]
            if @opts[:subdued]
              print "."
            else
              @log.info msg 
            end
          end
        when :warning, :warn
          @log.warn msg
      else
        print "!" if @opts[:subdued]
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

      @content_hash    = Hash.new {|h,k| h[k]= nil }
      @layouts         = Hash.new {|h,k| h[k]= nil }
      @partials        = Hash.new {|h,k| h[k]= nil }
      @generators      = Hash.new {|h,k| h[k]= nil }
      
      @config          = Gumdrop::Config.new DEFAULT_OPTIONS
      @config.env      = @opts[:env] if @opts.has_key? :env

      clear_on_start()
      clear_on_before_scan()
      clear_on_scan()
      clear_on_before_generate()
      clear_on_generate()
      clear_on_before_render()
      clear_on_render()
      clear_on_before_render_item()
      clear_on_render_item()
      clear_on_end()

      load_sitefile()
      
      @data_path       = get_expanded_path(@config.data_dir)
      @src_path        = get_expanded_path(@config.source_dir)
      @out_path        = get_expanded_path(@config.output_dir)

      @data            = Gumdrop::DataManager.new self, @data_path

      init_logging()
    end

    def match_nodes(pattern, opts={})
      nodes = opts[:as] == :hash ? {} : []
      @content_hash.keys.each do |path|
        if path_match path, pattern
          if opts[:as] == :hash
            nodes[path]= @content_hash[path]
          else
            nodes << @content_hash[path]
          end
        end
      end
      nodes
    end

    def init_logging
      begin
        @log = Logger.new @config.log, 'daily'
      rescue
        target= if @opts[:quiet]
          nil
        else
          STDOUT
        end
        @log = Logger.new target
        # report "Using STDOUT for logging because of exception: #{ $! }" unless target.nil?
      end
      @log.formatter = proc do |severity, datetime, progname, msg|
        # "#{datetime}: #{msg}\n"
        "  #{msg}\n"
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
              @content_hash[path]= node
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
        nodes= if opts[:assets]
          contents(opts[:assets])
        else
          contents()
        end
        nodes.each do |node|
          render_content(node, render_context, content_filters)
        end
        on_render(self)
      end
    end

    def render_content(node, ctx, filters)
      unless node.ignore?
        output_path= File.join(@out_path, node.to_s)
        FileUtils.mkdir_p File.dirname(output_path)
        begin
          on_before_render_item(self, node)
          node.renderTo ctx, output_path, filters
          on_render_item(self, node)
        rescue => ex
          report "[!>EXCEPTION<!]: #{ node.to_s }", :error
          report [ex.to_s, ex.backtrace].flatten.join("\n"), :error
          exit 1 unless @opts[:resume]
        end
      else
        report "  ignoring: #{ node.to_s }", :info
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

    def tasks(&block)
      Gumdrop::CLI::Internal.class_eval &block
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
    def on_before_render_item(&block)
      @site.on_before_render &block
    end
    def on_render_item(&block)
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