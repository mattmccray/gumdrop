
module Gumdrop::Support

  module Sprockets # mixes in to generator
    
    def sprockets(source_file, opts={})
      require 'sprockets'
      source_path = source_file || opt[:main] || opt[:from]
      env = ::Sprockets::Environment.new site.root
      env.append_path site.source_path
      env.append_path File.dirname(source_path)
      [opts[:paths]].flatten.each do |path|
        env.append_path(path) unless path.nil?
      end
      content= env[ source_path ].to_s
    rescue LoadError
      raise StandardError, "Sprockets can't be loaded. Please add it to your Gemfile."
    end

  end

  Gumdrop::Generator::DSL.send :include, Sprockets

end

