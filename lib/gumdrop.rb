# coding: utf-8

require 'tilt'
require "active_support/core_ext"
require 'gumdrop/util/string_ex'

module Gumdrop

  autoload :Server, 'gumdrop/server/server'

  module CLI
    autoload :Internal, 'gumdrop/cli/internal'
    autoload :External, 'gumdrop/cli/external'
  end

  module Data
    autoload :Manager, 'gumdrop/data/manager'
  end

  module Support
    autoload :BasePackager, 'gumdrop/support/base_packager'    
    autoload :Stitch, 'gumdrop/support/stitch'
    autoload :Sprockets, 'gumdrop/support/sprockets'
  end

  module Util
    autoload :Eventable, 'gumdrop/util/eventable'
    autoload :HashObject, 'gumdrop/util/hash_object'
    autoload :Loggable, 'gumdrop/util/logging'
    autoload :SiteAccess, 'gumdrop/util/site_access'
    autoload :ViewHelpers, 'gumdrop/util/view_helpers'
  end

  def self.change_log
    here= File.dirname(__FILE__)
    File.read here / ".." / "ChangeLog.md"
  end

end

require 'gumdrop/version'
require 'gumdrop/builder'
require 'gumdrop/content'
require 'gumdrop/generator'
require 'gumdrop/renderer'
require 'gumdrop/site'
require 'gumdrop/cli'
