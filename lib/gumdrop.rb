# coding: utf-8

require 'tilt'
require "active_support/core_ext"
require 'gumdrop/util/core_ex'

# The simple and sweet static CMS! (and prototyping tool)
module Gumdrop

  autoload :Server, 'gumdrop/server'

  module CLI
    autoload :Internal, 'gumdrop/cli/internal'
    autoload :External, 'gumdrop/cli/external'
  end

  module Support
    autoload :Compressor, 'gumdrop/support/compressor'
    autoload :Stitch, 'gumdrop/support/stitch'
    autoload :Sprockets, 'gumdrop/support/sprockets'
  end

  module Util
    autoload :Configurable, 'gumdrop/util/configurable'
    autoload :Eventable, 'gumdrop/util/eventable'
    autoload :HashObject, 'gumdrop/util/hash_object'
    autoload :Loggable, 'gumdrop/util/logging'
    autoload :Scanner, 'gumdrop/util/scanner'
    autoload :SiteAccess, 'gumdrop/util/site_access'
    autoload :ViewHelpers, 'gumdrop/util/view_helpers'
    autoload :YamlDoc, 'gumdrop/util/yaml_doc'
  end

  # Returns 'ChangeLog.md' from gem package.
  def self.change_log
    here= File.dirname(__FILE__)
    File.read here / ".." / "ChangeLog.md"
  end

end

require 'gumdrop/cli'
require 'gumdrop/builder'
require 'gumdrop/content'
require 'gumdrop/data'
require 'gumdrop/generator'
require 'gumdrop/renderer'
require 'gumdrop/site'
require 'gumdrop/version'

Dir[File.dirname(__FILE__) / 'gumdrop' / 'support' / '*.rb'].each do |lib|
  require lib
end