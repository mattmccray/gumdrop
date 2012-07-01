require 'active_support/configurable'

module Gumdrop

  WEB_PAGE_EXTS= %w(.html .htm .php)
  JETSAM_FILES= %w(**/.DS_Store .gitignore .git/**/* .svn/**/* **/.sass-cache/**/* Gumdrop)

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
    server_timeout: 5,
    server_port: 4567,
    env: :production,
    file_change_test: :default
  }

  class Site
    include ActiveSupport::Configurable
    include Util::Eventable
    include Util::Loggable

    config_accessor :source_dir, :output_dir, :data_dir, :mode, :env

    attr_reader :sitefile, :options, :root, :contents, :data, :blacklist, :greylist, :filters, :layouts, :generators, :partials, :last_run

    # You shouldn't call this yourself! Access it via Gumdrop.site
    def initialize(sitefile, opts={})
      @options=Util::HashObject.from opts
      _options_updated!
      @sitefile= sitefile.expand_path
      @root= File.dirname @sitefile
      @last_run = 0
      @contents = ContentList.new
      @layouts = SpecialContentList.new ".layout"
      @partials = SpecialContentList.new
      @generators = []
      @filters = []
      @blacklist = []
      @greylist = []
      @data= Data::Manager.new
      @scanned= false
      # Kind of a hack. But makes it testable
      Gumdrop.active_site= self if Gumdrop.active_site.nil?
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
        Content.path_match? path, pattern
      end
    end

    def in_blacklist?(path)
      @blacklist.any? do |pattern|
        Content.path_match? path, pattern
      end
    end

    def source_path
      @source_path ||= source_dir.expand_path(root)
    end

    def output_path
      @output_path ||= output_dir.expand_path(root)
    end

    def data_path
      @data_path ||= source_dir.expand_path(root)
    end

    # Events stop bubbling here.
    def parent
      nil
    end

  private

    def _options_updated!
      Site.configure do |c|
        c.env= @options.env.to_sym if @options.env
        c.mode= @options.mode.nil? ? :unknown : @options.mode.to_sym
      end
    end

    def _load_sitefile
      clear_events
      load sitefile
      data.add_path data_dir.expand_path(root)
      Gumdrop.init_logging
    end

    def _content_scanner
      log.debug "[Scanning from #{ source_path }]"
      # Report blacklists and greylists
      blacklist.each {|p| log.debug "   will skip: #{path}" }
      greylist.each  {|p| log.debug " will ignore: #{path}" }
      # Scan Filesystem
      event_block :scan do
        Scanner.new(source_path).each do |path, rel|
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
      Site.configure &block
    end

    def config
      site.config
    end

    def mode
      site.mode
    end

    def ignore
      site.greylist
    end
    def greylist
      site.greylist
    end

    def skip
      site.blacklist
    end
    def blacklist
      site.blacklist
    end

    # attr_reader would be better... but less testable :-)
    attr_accessor :active_site 

    def in_site_folder?(filename="Gumdrop")
      !fetch_site_file(filename).nil?
    end

    def site(opts={}, prefer_existing=true)
      if !@active_site.nil? and prefer_existing
        @active_site.options= opts unless opts.empty?
        @active_site
      else
        site_file= Gumdrop.fetch_site_file
        unless site_file.nil?
          @active_site= Site.new site_file, opts
        else
          nil
        end
      end
    end

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

  end

end

Gumdrop::Site.configure do |c|
  c.merge! Gumdrop::DEFAULT_CONFIG
end
