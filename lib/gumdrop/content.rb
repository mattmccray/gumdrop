
module Gumdrop
  
  class Content
    
    attr_accessor :path, 
                  :level, 
                  :filename, 
                  :source_filename, 
                  :type, 
                  :ext, 
                  :uri, 
                  :slug, 
                  :template, 
                  :params, 
                  :site, 
                  :ignored, 
                  :generated,
                  :full_path
    
    def initialize(path, site, params={})
      @site= site
      @params= HashObject.new params
      @full_path= path
      @ignored= false
      @generated= false
      @path= get_source_path
      @level= (@path.split('/').length - 1)
      @source_filename= File.basename path
      @filename= get_target_filename
      @type= File.extname @source_filename
      @ext= File.extname @filename
      @uri= get_uri
      @slug=@uri.gsub('/', '-').gsub(@ext, '')
      @template= unless Tilt[path].nil?
        Tilt.new path
      else
        nil
      end
    end
    
    def render(context=nil, ignore_layout=false, reset_context=true, locals={})
      context= @site.render_context if context.nil?
      if reset_context
        default_layout= (@ext == '.css' or @ext == '.js' or @ext == '.xml') ? nil : 'site'
        context.reset_data 'current_depth'=>@level, 'current_slug'=>@slug, 'page'=>self, 'layout'=>default_layout, 'params'=>self.params
      end
      context.set_content self, locals
      content= @template.render(context) 
      return content if ignore_layout
      layout= context.get_template()
      while !layout.nil?
        content = layout.template.render(context, content:content) { content }
        layout= context.get_template()
      end
      content
    end
    
    def renderTo(context, output_path, filters=[], opts={})
      return copyTo(output_path, opts) unless useLayout?
      @site.report " Rendering: #{@uri}", :warning
      output= render(context)
      filters.each {|f| output= f.call(output, self) }
      File.open output_path, 'w' do |f|
        f.write output
      end
    end
          
    
    def copyTo(output, layout=nil, opts={})
      do_copy= if File.exists? output
        !FileUtils.identical? @full_path, output
      else
        true
      end
      if do_copy
        @site.report "   Copying: #{@uri}", :warning
        FileUtils.cp_r @full_path, output, opts
      else
        @site.report "    (same): #{@uri}", :info
      end
    end
    
    def mtime
      if File.exists? @full_path
        File.new(@full_path).mtime
      else
        Time.now
      end
    end
    
    def useLayout?
      !@template.nil?
    end

    def ignore?
      @ignored
    end
    
    def to_s
      @uri
    end
  
  private

    def get_source_path
      path= @full_path.sub @site.src_path, ''
      if path[0] == '/'
        path[1..-1] 
      else
        path
      end
    end

    def get_target_filename
      filename_parts= @source_filename.split('.')
      ext= filename_parts.pop
      while !Tilt[ext].nil?
        ext= filename_parts.pop
      end
      filename_parts << ext # push the last file ext back on there!
      filename_parts.join('.')
    end

    def get_uri
      uri= File.join File.dirname(@path), @filename
      if uri.starts_with? './'
        uri[2..-1]
      else
        uri
      end
    end
    
  end
  
end
