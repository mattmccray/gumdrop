# Any specialized code for your site goes here...

puts "Build: #{Gumdrop.data.config.title} (gumdrop v#{Gumdrop::VERSION})"

if defined? Encoding
  Encoding.default_internal = Encoding.default_external = "UTF-8"
else
  $KCODE = "UTF-8"
end

require 'slim'
Slim::Engine.set_default_options pretty:true

# If you want to specify custom stitch compilers, uncomment this:
#require 'stitch_compilers'

generate do

  stitch 'app.js',        # JavaScript to assemble
    :identifier=>'app',   # variable name for the library
    :paths=>['./app'],
    :root=>'./app', 
    :prune=>false,        # If true, removes the source files from Gumdrop.site hash
    :compress=>:jsmin,    # Options are :jsmin, :yuic, :uglify
    :obfuscate=>false,    # For compressors that support munging/mangling
    :keep_src=>true       # Creates another file, ex: app-src.js

  stitch 'lib.js', 
    :identifier=>'lib', 
    :paths=>['./lib/javascript'], 
    :root=>'./lib/javascript', 
    :prune=>true, 
    :compress=>false, 
    :obfuscate=>false, 
    :keep_src=>false

  
# Examples of other generatory things:
#
#   page "about.html", :template=>'about', :passthru=>'Available in the template' # requires a about.template.XX file
#  
#   page 'robots.txt' do
#     # And content returned will be put in the file
#     """
#     User-Agent: *
#     Disallow: /
#     """
#   end
#
#   # Maybe for a tumblr-like pager
#   pager= Gumdrop.data.pager_for :posts, base_path:'posts/page', page_size:5
#   pager.each do |page|
#     page "#{page.uri}.html", template:'post_page', posts:page.items, pager:pager, current_page:pager.current_page
#   end

end

# Example of skipping a source file from compilation (stitch ignores this setting)
# skip 'file-to-ignore.html'

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
