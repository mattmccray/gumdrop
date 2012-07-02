module Gumdrop

  WEB_PAGE_EXTS= %w(.html .htm .php)
  JETSAM_FILES= %w(**/.DS_Store .git* .git/**/* .svn/**/* **/.sass-cache/**/* Gumdrop)

  DEFAULT_CONFIG= {
    relative_paths: true,
    relative_paths_exts: WEB_PAGE_EXTS,
    default_layout: 'site',
    layout_exts: WEB_PAGE_EXTS,
    proxy_enabled: false,
    output_dir: "./output",
    source_dir: "./source",
    data_dir: './data',
    log: STDOUT,
    log_level: :info,
    ignore: JETSAM_FILES,
    blacklist: [],
    greylist: [],
    server_timeout: 5,
    server_port: 4567,
    env: :production,
    file_change_test: :default,
    renderer: Renderer,
    builder: Builder
  }

  class Site
    include Util::Configurable
    include Util::Eventable
    include Util::Loggable

    config_accessor :source_dir, :output_dir, :data_dir, :mode, :env

    attr_reader :sitefile, :options, :root, :contents, :data, 
                :blacklist, :greylist, :filters, :layouts, 
                :generators, :partials, :last_run

    # You shouldn't call this yourself! Access it via Gumdrop.site
    def initialize(sitefile, opts={})
      Gumdrop.send :set_current_site, self
      _reset_config
      @options= Util::HashObject.from opts
      _options_updated!
      @sitefile= sitefile.expand_path
      @root= File.dirname @sitefile
      @last_run= 0
      @contents= ContentList.new
      @layouts= SpecialContentList.new ".layout"
      @partials= SpecialContentList.new
      @generators= []
      @filters= []
      @blacklist= []
      @greylist= []
      @data= DataManager.new
      @scanned= false
      _load_sitefile
    end

    def options=(opts={})
      @options.merge!(opts)
      _options_updated!
    end


    def clear(reload_sitefile=false)
      @contents.clear
      @layouts.clear
      @partials.clear
      @generators.clear
      @filters.clear
      @blacklist.clear
      @greylist.clear
      @data.reset
      @output_path= nil
      @source_path= nil
      @data_path= nil
      @scanned= false
      _load_sitefile if reload_sitefile
      self
    end

    def scan(force=false)
      if !@scanned or force
        clear(true) if @scanned # ????
        _content_scanner
        @scanned= true
        generate
      end
      self
    end

    def generate
      _execute_generators
      self
    end

    def in_greylist?(path)
      @greylist.any? do |pattern|
        path.path_match? pattern
      end
    end

    def in_blacklist?(path)
      @blacklist.any? do |pattern|
        path.path_match? pattern
      end
    end

    def ignore_path?(path)
      config.ignore.any? do |pattern|
        path.path_match? pattern
      end
    end

    def source_path
      @source_path ||= source_dir.expand_path(root)
    end

    def output_path
      @output_path ||= output_dir.expand_path(root)
    end

    def data_path
      @data_path ||= data_dir.expand_path(root)
    end

    # Events stop bubbling here.
    def parent
      nil
    end

  private

    def _reset_config
      config.clear.merge! DEFAULT_CONFIG
    end

    def _options_updated!
      config.env= @options.env.to_sym if @options.env
      config.mode= @options.mode.nil? ? :unknown : @options.mode.to_sym
    end

    def _load_sitefile
      clear_events
      load sitefile
      data.dir= data_dir.expand_path(root)
      Gumdrop.init_logging
    end

    def _content_scanner
      log.debug "[Scanning from #{ source_path }]"
      # Report blacklists and greylists
      blacklist.each {|p| log.debug "   will skip: #{path}" }
      greylist.each  {|p| log.debug " will ignore: #{path}" }
      # Scan Filesystem
      event_block :scan do
        scanner= Util::Scanner.new(source_path, {}, &method(:_scanner_validator)) 
        scanner.each do |path, rel|
          content= Content.new(path)
          layouts.add content and next if content.layout?
          partials.add content and next if content.partial?
          generators << Generator.new(content) and next if content.generator?
          contents.add content
          log.debug " including: #{ rel }"
        end
        contents.keys.size
      end
    end

    def _scanner_validator(source_path, full_path)
      return true if ignore_path? source_path
      in_blacklist? source_path
    end

    def _execute_generators
      log.debug "[Executing Generators]"
      event_block :generate do
        generators.each do |generator|
          generator.execute()
        end
      end
    end

  end

  class << self

    def on(event_type, options={}, &block)
      site.on event_type, options, &block
    end

    def configure(&block)
      site.configure &block
    end

    def config
      site.config
    end

    def mode
      site.mode
    end

    def in_site_folder?(filename="Gumdrop")
      !fetch_site_file(filename).nil?
    end

    def site(opts={}, force_new=false)
      opts= opts.to_symbolized_hash
      unless @current_site.nil? or force_new
        @current_site.options= opts unless opts.empty?
        @current_site
      else
        site_file= fetch_site_file
        unless site_file.nil?
          Site.new site_file, opts
        else
          nil
        end
      end
    end

    # Protected too?
    def fetch_site_file(filename="Gumdrop")
      here= Dir.pwd
      found= File.file?  here / filename
      # TODO: Should be smarter -- This is a hack for Windows support "C:\"
      while !found and File.directory?(here) and File.dirname(here).length > 3
        here= File.expand_path here /'..'
        found= File.file?  here / filename
      end
      if found
        File.expand_path here / filename
      else
        nil
      end
    end

    def site_dirname(filename="Gumdrop")
      File.dirname( fetch_site_file( filename ) )
    end

  protected

    def set_current_site(site)
      @current_site= site
    end

  end

end

