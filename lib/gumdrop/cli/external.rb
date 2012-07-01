require 'fileutils'
require 'thor'

module Gumdrop::CLI
  class External < Thor
    include Thor::Actions

    def self.source_root
      File.expand_path('../../../..', __FILE__)
    end

    desc 'new [NAME]', 'Create new gumdrop project'
    method_option :template, aliases:'-t', desc:'Template to start from', required:true, default:'default'
    def new(name)
      template= options[:template] || 'default'

      if File.directory? gem_template_path(template)
        say "New site from template: #{template} (gem)"
        directory(gem_template_path(template), name)

      elsif File.directory? home_template_path(template)
        say "New site from template:  #{template} (local)"
        directory(home_template_path(template), name)

      else
        say "Unknown template!!\n"
        say "Please select from one of the following:\n\n"
        self.templates
      end
    end

    desc 'templates', 'List templates'
    def templates
      say  "Gem templates:"
      Dir[ gem_template_path ].each do |name|
        say " - #{File.basename name}" if File.directory?(name)
      end
      say  "Local templates:"
      Dir[ home_template_path t].each do |name|
        say " - #{File.basename name}" if File.directory?(name)
      end
    end

    private

      def gem_template_path(template='*')
        self.class.source_root / 'templates' / template
      end

      def home_template_path(template='*')
        File.expand_path "~" / '.gumdrop' / 'templates' / template
      end

  end
end