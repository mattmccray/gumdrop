
module Gumdrop
  
  class Content

    MUNGABLE_RE= Regexp.new(%Q<(href|data|src)([\s]*)=([\s]*)('|"|&quot;|&#34;|&#39;)?\\/([\\/]?)>, 'i')
    LAYOUTLESS_EXTS= %w(.css .js .xml)
    
    attr_reader :full_path, :path, :params, :site
    
    def initialize(path, site, params={})
      @site= site
      @params= HashObject.new params
      @full_path= path
    end

    def slug
      @slug ||= uri.gsub('/', '-').gsub(ext, '')
    end

    def ignored
      @ignored ||= false
    end
    def ignore(state=true)
      @ignored= state
    end

    def generated
      @generated ||= false
    end

    def path
      @path ||= get_source_path
    end

    def level
      @level ||= (path.split('/').length - 1)
    end

    def source_filename
      @source_filename ||= File.basename @full_path
    end

    def filename
      @filename ||= get_target_filename
    end

    def type
      @type ||= File.extname source_filename
    end

    def ext
      @ext ||= File.extname filename
    end

    def uri
      @uri ||= get_uri
    end

    def template
      @template ||= unless Tilt[@full_path].nil?
        Tilt.new @full_path
      else
        nil
      end
    end
    def template=(t)
      @template = t
    end
    
    def render(context=nil, ignore_layout=false, reset_context=true, locals={})
      context= site.render_context if context.nil?
      if reset_context
        default_layout= LAYOUTLESS_EXTS.include?(ext) ? nil : 'site'
        context.reset_data 'current_depth'=>level, 'current_slug'=>slug, 'page'=>self, 'layout'=>default_layout, 'params'=>params
      end
      context.set_content self, locals
      content= render_all(context)
      return content if ignore_layout
      layout= context.get_template()
      while !layout.nil? and !layout.template.nil?
        content = layout.template.render(context, content:content) { content }
        layout= context.get_template()
      end
      relativize content, context
    end
    
    def renderTo(context, output_path, filters=[], opts={})
      return copyTo(output_path, opts) unless useLayout?
      site.report " rendering: #{uri}", :warning
      output= render(context)
      filters.each {|f| output= f.call(output, self) }
      File.open output_path, 'w' do |f|
        f.write output
      end
    end
          
    # This probably belongs to the BUILD, not here
    def copyTo(output, layout=nil, opts={})
      do_copy= if File.exists? output
        !FileUtils.identical? @full_path, output
      else
        true
      end
      if do_copy
        site.report "   copying: #{uri}", :warning
        FileUtils.cp_r @full_path, output, opts
      else
        site.report "    (same): #{uri}", :info
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
      !template.nil?
    end

    def ignore?
      ignored
    end
    
    def to_s
      uri
    end
  
  private

    def get_source_path
      path= @full_path.sub site.src_path, ''
      if path[0] == '/'
        path[1..-1] 
      else
        path
      end
    end

    def get_target_filename
      filename_parts= source_filename.split('.')
      ext= filename_parts.pop
      while !Tilt[ext].nil?
        ext= filename_parts.pop
      end
      filename_parts << ext # push the last file ext back on there!
      filename_parts.join('.')
    end

    def render_all(ctx)
      if generated or !File.exists?(@full_path)
        content= template.render(ctx)
      else
        content= File.read @full_path
        exts= source_filename.gsub filename, ''
        exts.split('.').reverse.each do |ext|
          unless ext.blank?
            templateClass= Tilt[".#{ext}"]
            template= templateClass.new(@full_path) do
              content
            end
            content= template.render(ctx)
          end
        end
      end
      content
    end

    def get_uri
      uri= File.join File.dirname(path), filename
      if uri.starts_with? './'
        uri[2..-1]
      else
        uri
      end
    end

    def relativize(content, ctx)
      if site.config.relative_paths and !ctx.force_absolute
        if site.config.relative_paths_for == :all or site.config.relative_paths_for.include?(ext)
          path_to_root= ctx.path_to_root
          content.force_encoding("UTF-8") if content.respond_to? :force_encoding
          content = content.gsub MUNGABLE_RE do |match|
            if $5 == '/'
              "#{ $1 }#{ $2 }=#{ $3 }#{ $4 }/"
            else
              "#{ $1 }#{ $2 }=#{ $3 }#{ $4 }#{ path_to_root }"
            end
          end
        end
      end
      content
    end
    
  end
  
end
