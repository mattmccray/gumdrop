# Gumdrop

Gumdrop is a small and sweet cms/prototype tool. It can generate static html and includes a dev server that can be run via any rack server (including POW!).

## Install

    gem install gumdrop




# NEEDS TO BE REWRITTEN FROM HERE:d




# CLI Quick Ref

### Create New Site

    gumdrop --create my_new_site

Shorter syntax:

    gumdrop -c my_new_site

### Create New Site From Template

    gumdrop -c my_new_site -t backbone


### Build Static HTML

    gumdrop -b

Or, you can use Rake:

    rake build


### Start Dev Server

    gumdrop -s

Or, using Rake again:

    rake serve

### Saving The Current Site As A Local Template

    gumdrop -t my_template

You can then create new sites based on your local template:

    gumdrop -c my_new_from_my_template -t my_template

Local templates are stored under `~/.gumdrop/templates/`.



# Gumdrop File

Gumdrop looks for a file named `Gumdrop` to indicate the root folder of your project. It'll walk up the directory structure looking for one, so you can run Gumdrop commands from sub-folders.

The `Gumdrop` file is where you configure your site, generate dynamic content, assign view_helpers and more.

Here's the `Gumdrop` file created by the default template:

    puts "Gumdrop v#{Gumdrop::VERSION} building..."

    configure do

      set :site_title,   "My Site"
      set :site_tagline, "My home on thar intarwebs!"
      set :site_author,  "Me"
      set :site_url,     "http://www.mysite.com"
      
      #  All the supported build configuration settings and their defaults:
      # set :relative_paths, true
      # set :proxy_enabled, true
      # set :output_dir, "./output"
      # set :source_dir, "./source"
      # set :data_dir, './data'
      # set :log, './logs/build.log'
      # set :ignore, %w(.DS_Store .gitignore .git .svn .sass-cache)
      # set :server_timeout, 15
      # set :server_port, 4567

    end


    #  Skipping files entirely from build process... Like they don't exist.
    # skip 'file-to-ignore.html'
    # skip 'dont-show/**/*'

    #  Ignores source file(s) from compilation, but does load the content into memory
    # ignore 'pages/**/*.*'

    #  NOTE: Skipping and ignoring matches like a file glob (it use File.fnmatch in fact)
    #       (this doesn't work for files detected by stitch)


    # Example site-level generator
    generate do
      
      #  Requires a about.template.XX file
      # page "about.html", 
      #   :template=>'about', 
      #   :passthru=>'Available in the template'

      # page 'robots.txt' do
      #   # And content returned will be put in the file
      #   """
      #   User-Agent: *
      #   Disallow: /
      #   """
      # end

      #  Maybe for a tumblr-like pager
      # pager= Gumdrop.data.pager_for :posts, base_path:'posts/page', page_size:5

      # pager.each do |page|
      #   page "#{page.uri}.html", 
      #     template:'post_page', 
      #     posts:page.items, 
      #     pager:pager, 
      #     current_page:pager.current_page
      # end

      #  Assemble javscript files in a CommonJS-like way with stitch-rb
      # stitch 'app.js',        # JavaScript to assemble
      #   :identifier=>'app',   # variable name for the library
      #   :paths=>['./app'],
      #   :root=>'./app', 
      #   :dependencies=>[],    # List of scripts to prepend to top of file (non moduled)
      #   :prune=>false,        # If true, removes the source files from Gumdrop.site hash
      #   :compress=>:jsmin,    # Options are :jsmin, :yuic, :uglify
      #   :obfuscate=>false,    # For compressors that support munging/mangling
      #   :keep_src=>true       # Creates another file, ex: app-src.js
       
    end

    # Example of using a content filter to compress CSS output
    # require 'yui/compressor'
    # content_filter do |content, info|
    #   if info.ext == '.css'
    #     puts "  Compress: #{info.filename}"
    #     compressor= YUI::CssCompressor.new
    #     compressor.compress( content )
    #   else
    #     content
    #   end
    # end


    # View helpers (available in rendering context):
    view_helpers do

      # Calculate the years for a copyright
      def copyright_years(start_year, divider="&#8211;")
        end_year = Date.today.year
        if start_year == end_year
          "#{start_year}"
        else
          "#{start_year}#{divider}#{end_year}"
        end
      end
      
      #
      # Your custom helpers go here!
      #

    end

    # Any specialized code for your site goes here...

    require 'slim'
    Slim::Engine.set_default_options pretty:true


# Need To Document:

- Proxy support
- Stitch
- "Dynamic" pages
- Data support
- Content filters
- Partials
- Config and using in pages
- Project Templates

# Todo / Ideas / Changes
- Create guard-gumdrop.
- Add automatic sqlite loading to `data_manager`?
- New/Update Doc site.
- Need test coverage.
- Some kind of admin? What would that even do?
    - If you could specify a 'prototype' for data collections, could be cool.
- Add YamlDoc support for nodes? (Tilt compiler? or in Content)
