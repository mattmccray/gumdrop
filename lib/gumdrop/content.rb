
module Gumdrop
  
  class Content
    
    attr_accessor :path, :level, :filename, :source_filename, :type, :ext, :uri, :slug, :template, :params
    
    def initialize(path, params={})
      @params= HashObject.new params
      @path= path
      @level= (@path.split('/').length - 2)
      @source_filename= File.basename path
      filename_parts= @source_filename.split('.')
      @filename= filename_parts[0..1].join('.')      
      path_parts= @path.split('/')
      path_parts.shift
      path_parts.pop
      path_parts.push @filename
      @type= filename_parts.last
      @ext= File.extname @filename
      @uri= path_parts.join('/')
      @slug=@uri.gsub('/', '-').gsub(@ext, '')
      @template= unless Tilt[path].nil?
        Tilt.new path
      else
        nil
      end
    end
    
    def render(ignore_layout=false, reset_context=true, locals={})
      if reset_context
        default_layout= (@ext == '.css' or @ext == '.js' or @ext == '.xml') ? nil : 'site'
        Context.reset_data 'current_depth'=>@level, 'current_slug'=>@slug, 'page'=>self, 'layout'=>default_layout, 'params'=>self.params
      end
      Context.set_content self, locals
      content= @template.render(Context)
      return content if ignore_layout
      layout= Context.get_template()
      while !layout.nil?
        content = layout.template.render(Context, :content=>content)
        layout= Context.get_template()
      end
      content
    end
    
    def renderTo(output_path, opts={})
      return copyTo(output_path, opts) unless useLayout?
      output= render()
      File.open output_path, 'w' do |f|
        puts " Rendering: #{@uri}"
        f.write output
      end
    end
    
    def copyTo(output, layout=nil, opts={})
      do_copy= if File.exists? output
        !FileUtils.identical? @path, output
      else
        true
      end
      if do_copy
        puts "   Copying: #{@uri}"
        FileUtils.cp_r @path, output, opts
      else
        puts "    (same): #{@uri}"
      end
    end
    
    def useLayout?
      !@template.nil?
    end
    
    def to_s
      @uri
    end
    
  end
  
end