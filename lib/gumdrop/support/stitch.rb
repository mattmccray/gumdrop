# stitch.rb
begin
  require 'stitch-rb'
  has_stitch= true
rescue LoadError
  has_stitch= false
end

# TODO: Use Compressor object
# TODO: Better extend

module Gumdrop::Support

  module Stitch # mixes in to generator
    

    def stitch(name, opts)
      if has_stitch
        content= Stitch::Package.new(opts).compile
        page name do
          compress_output(content, opts)
        end
        keep_src(name, content, opts)
        prune_src(name, opts)
      else
        throw "Stitch can't be loaded. Please add it to your Gemfile."
      end
    end

      def keep_src(name, content, opts)
        if opts[:keep_src] or opts[:keep_source]
          ext= File.extname name
          page name.gsub(ext, "#{opts.fetch(:source_postfix, '-src')}#{ext}") do
            content
          end
        end
      end
      
      def prune_src(name, opts)
        if opts[:prune] and opts[:root]
          sp = site.source_path
          rp = File.expand_path(opts[:root])
          relative_root = rp.gsub(sp, '')[1..-1]
          rrlen= relative_root.length - 1
          @site.content_hash.keys.each do |path|
            if path[0..rrlen] == relative_root and name != path
              @site.content_hash.delete path
            end
          end
        end
      end


  end

end

if defined?(Stitch)

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