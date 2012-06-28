# site_cli.rb
# require 'pathname'
require 'fileutils'
require 'listen'
# require 'rack'
require 'thor'

module Gumdrop::CLI
  class Internal < Thor
    include Thor::Actions

    def self.source_root
      File.expand_path('../../..', __FILE__)
    end

    desc 'build', 'Build project'
    method_option :env, default:'production', aliases:'-e'
    method_option :quiet, default:false, aliases:'-q', type: :boolean
    method_option :resume, default:false, aliases:'-r', type: :boolean, desc:"Auto resume rendering after any errors"
    def build
      Gumdrop.run(options)
    end

    desc 'server', 'Run development server'
    def server
      Gumdrop::Server
    end

    desc 'watch', "Watch filesystem for changes and recompile"
    method_option :quiet, default:false, aliases:'-q', type: :boolean
    method_option :resume, default:false, aliases:'-r', type: :boolean, desc:"Auto resume rendering after any errors"
    def watch
      Gumdrop.run options
      paths= [SITE.src_path]
      paths << SITE.data_path if File.directory? SITE.data_path
      Listen.to(*paths, :latency => 0.5) do |m, a, r|
        SITE.rebuild
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
        site_root= Gumdrop.site_dirname
        FileUtils.mkdir_p File.dirname(template_path)
        FileUtils.cp_r File.join(site_root, "."), template_path
      end
    end

    private
      
      def home_path(name="")
        File.expand_path File.join("~", ".gumdrop", name)
      end

      def home_template_path(template)
        home_path 'tempaltes', template
      end

      def local_path(name="")
        File.join( ".", name ) # ?
      end
  end
end

SITE= Gumdrop::Site.new Gumdrop.fetch_site_file unless defined?( SITE )
