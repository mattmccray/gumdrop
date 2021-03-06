# stitch.rb
begin
  require 'stitch-rb'
  has_stitch= true
rescue LoadError
  has_stitch= false
end

module Gumdrop::Support

  module Stitch # mixes in to generator
    
    # Stitch::Package.new options:
    #   :identifier=>'app',   # variable name for the library
    #   :paths=>['./app'],
    #   :root=>'./app', 
    #   :dependencies=>[],    # List of scripts to prepend to top of file (non moduled)
    def stitch(source_file, opts={})
      require 'stitch-rb'
      content= site.resolve source_file
      path = content.nil? ? source_file : content.source_path
      stitch_opts= {} #{ root: content.source_path }
      stitch_opts.merge! opts
      stitch_opts[:paths] ||= []
      if stitch_opts.fetch(:autorootpath, true)
        stitch_opts[:paths] << File.dirname(path) 
      end
      ::Stitch::Package.new(stitch_opts).compile
    rescue LoadError
      raise StandardError, "Stitch can't be loaded. Please add it to your Gemfile."
    end

  end

  Gumdrop::Generator::DSL.send :include, Stitch

end


#
# These cause weird side effects, need to pull them out into a js-app
# specific template!
#
if false # defined?(Stitch)

  class Stitch::Source
    # Patch for gumdrop style filenames
    def name
      name = path.relative_path_from(root)
      name = name.dirname + name.basename(".*")
      name.to_s.gsub(".js", '')
    end
  end


  # Custom Compilers


  class SerenadeCompiler < Stitch::Compiler
    
    extensions :serenade
    
    def compile(path)
      content= File.read(path)
      viewname= File.basename(path).gsub('.serenade', '').gsub('.html', '').gsub('.', '_')
      %{
        Serenade.view(#{ viewname.to_json }, #{content.to_json});
      }
    end
    
  end

  # Not so sure on this one...
  class HoganCompiler < Stitch::Compiler
    # List of supported extensions
    extensions :mustache

    # A compile method which takes a file path,
    # and returns a compiled string
    def compile(path)
      content = File.read(path)
      %{
        var template = Hogan.compile(#{content.to_json});
        module.exports = (function(data){ return template.render(data); });
      }
    end
  end

  module CssJsCode
    
    def export_js_code(path)
      content= File.read(path)
      %{
        var css = #{ transpile(content, File.extname(path)).to_json },
            node = null;
        module.exports= {
          content: css,
          add: function(to){
            if(node != null) return;
            if(to == null) to= document.getElementsByTagName('HEAD')[0] || document.body;
            node= document.createElement('style');
            node.innerHTML= css;
            to.appendChild(node);
            return this;
          },
          remove: function() {
            if(node != null) {
              node.parentNode.removeChild(node);
              node = null;
            }
            return this;
          }
        };
      }
    end

    def transpile(content, ext)
      content
    end

  end

  class CssCompiler < Stitch::Compiler
    include CssJsCode

    extensions :css

    def compile(path)
      export_js_code path
    end

  end


  begin
    require 'sass'

    class SassCompiler < Stitch::Compiler
      include CssJsCode

      extensions :sass, :scss

      def compile(path)
        export_js_code path
      end

      def transpile(content, ext)
        type = (ext == '.sass') ? :sass : :scss
        Sass::Engine.new(content, :syntax=>type).render
      end
    end

  rescue
    # Sass Not available
  end

end