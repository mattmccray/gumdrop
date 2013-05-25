require 'fileutils'
require 'thor'
require 'launchy'

module Gumdrop::CLI
  class Internal < Thor
    include Thor::Actions

    def self.source_root
      File.expand_path('../../..', __FILE__)
    end

    desc 'build', 'Build project'
    method_option :env, default:'production', aliases:'-e'
    method_option :assets, aliases:'-a', type: :array, desc:"List of assets to render."
    method_option :quiet, default:false, aliases:'-q', type: :boolean
    method_option :resume, default:false, aliases:'-r', type: :boolean, desc:"Auto resume rendering after any errors"
    method_option :force, default:false, aliases:'-f', type: :boolean, desc:"Ignore file checksums and create all files"
    def build
      if options[:quiet]
        Gumdrop.configure do |c|
          c.log_level= :warn
        end
      end
      Gumdrop.run options.merge(mode:'build')
    end

    desc 'server', 'Run development server'
    method_option :browser, aliases:'-b', default:false, desc:"Launch a browser to the site address."
    method_option :port, aliases:'-p', default:4567, desc:"Port to run the server on."
    def server
      Gumdrop.configure do |c|
        c.server_port= options[:port]
      end
      Gumdrop.site.options = options.merge(mode:'server')
      Launchy.open "http://127.0.0.1:#{ options[:port] }" if options[:browser]
      Gumdrop.log.warn "Launching dev server at http://127.0.0.1:#{ options[:port] }"
      Gumdrop::Server
    end

    desc 'template [NAME]', "Create local template from this project"
    def template(name)
      template= name
      template_path = home_template_path name
      if File.exists? template_path
        say "A template named '#{name}' already exists!"
      
      else
        say "Creating template:  #{name}"
        say "  ~/.gumdrop/templates/#{name}"
        site_root= Gumdrop.site.root
        FileUtils.mkdir_p File.dirname(template_path)
        FileUtils.cp_r (site_root / "."), template_path
      end
    end


    desc 'uris', "Print list of the uri that will be generated."
    def uris
      Gumdrop.configure do |c|
        c.log_level= :error
      end
      Gumdrop.site.scan

      say "Gumdrop found:"
      say ""
      Gumdrop.site.contents.keys.sort.each do |uri|
        content= Gumdrop.site.contents[uri]
        blackout= Gumdrop.site.in_blacklist?(uri) ? 'X' : ' '
        generated= content.generated? ? '*' : ' '
        # binary= content.binary? ? '!' : ' '
        # say " #{blackout + generated + binary} #{content.uri}"
        say " #{blackout + generated } #{content.uri}"
      end
      say ""
      say "Legend:"
      say "  X = On the blacklist"
      say "  * = Generated (not on fs)"
      # say "  ! = Binary file"
    end

    desc "version", "Displays Gumdrop version"
    def version
      say "Gumdrop v#{ Gumdrop::VERSION }"
    end

  private
    
    def home_path(name="")
      File.expand_path "~" /".gumdrop" / name
    end

    def home_template_path(template)
      home_path 'templates' / template
    end

    def local_path(name="")
      "." / name
    end
  end
end
