# sprockets.rb
begin
  require 'sprockets'
  has_sprockets= true
rescue LoadError
  has_sprockets= false
end

module Gumdrop::Support

  module Sprockets # mixes in to generator
    include BasePackager
    
    def sprockets(name, opts)
      if has_sprockets
        env = Sprockets::Environment.new @site.root_path
        env.append_path @site.src_path
        opts[:paths].each do |path|
          env.append_path(path)
        end
        content= env[ opts[:src] ].to_s
        page name do
          compress_output(content, opts)
        end
        keep_src(name, content, opts)
        prune_src(name, opts)
      else
        throw "Sprockets can't be loaded. Please add it to your Gemfile."
      end
    end

  end

end
