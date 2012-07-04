require 'fileutils'
require 'listen'
require 'thor'

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
    method_option :subdued, default:false, aliases:'-s', type: :boolean, desc:"Subdued output (....)"
    method_option :resume, default:false, aliases:'-r', type: :boolean, desc:"Auto resume rendering after any errors"
    method_option :checksums, default:false, aliases:'-c', type: :boolean, desc:"File changes validated against checksums"
    def build
      Gumdrop.run options.merge(mode:'build')
    end

    desc 'server', 'Run development server'
    def server
      Gumdrop.site.options = options.merge(mode:'build')
      Gumdrop::Server
    end

    desc 'watch', "Watch filesystem for changes and recompile"
    method_option :quiet, default:false, aliases:'-q', type: :boolean
    method_option :subdued, default:false, aliases:'-s', type: :boolean, desc:"Subdued output (....)"
    method_option :resume, default:false, aliases:'-r', type: :boolean, desc:"Auto resume rendering after any errors"
    def watch
      Gumdrop.run options.merge(mode:'merge')
      paths= [Gumdrop.site.source_dir, Gumdrop.site.sitefile] #? Sitefile too?
      paths << Gumdrop.site.data_dir if File.directory? Gumdrop.site.data_dir
      Listen.to(*paths, :latency => 0.5) do |m, a, r|
        Gumdrop.rebuild options.merge(mode:'merge')
      end
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
        binary= content.binary? ? '!' : ' '
        say " #{blackout + generated + binary} #{content.uri}"
      end
      say ""
      say "Legend:"
      say "  X = On on the blacklist"
      say "  * = Generated (not on fs)"
      say "  ! = Binary file"
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
