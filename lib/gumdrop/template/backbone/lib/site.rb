# Any specialized code for your site goes here...

puts "Build: #{Gumdrop.data.config.title} (gumdrop v#{Gumdrop::VERSION})"

if defined? Encoding
  Encoding.default_internal = Encoding.default_external = "UTF-8"
else
  $KCODE = "UTF-8"
end

require 'slim'
Slim::Engine.set_default_options pretty:true

require 'stitch_compilers'

generate do

  stitch 'app.js', :identifier=>'app', :paths=>['./app_src'], :root=>'./app_src', :prune=>false, :compress=>false
  stitch 'lib.js', :identifier=>'lib', :paths=>['./lib/javascript'], :root=>'./lib/javascript', :prune=>true, :compress=>false

  # Create minified 'production' versions
  #stitch 'app.min.js', :identifier=>'app', :paths=>['./app_src'], :root=>'./app_src', :prune=>false, :compress=>true
  #stitch 'lib.min.js', :identifier=>'lib', :paths=>['./lib/javascript'], :root=>'./lib/javascript', :prune=>true, :compress=>true

  
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
#   stitch 'app.js', :paths=>['source/app_src'], :root=>'source/app_src', :compress=>true, :prune=>true # Prune will remove the source files from the output tree -- you can add :dependencies=>['dir'] too
#
#   # Maybe for a tumblr-like pager
#   pager= Gumdrop.data.pager_for :posts, base_path:'posts/page', page_size:5
#   pager.each do |page|
#     page "#{page.uri}.html", template:'post_page', posts:page.items, pager:pager, current_page:pager.current_page
#   end

end

# Example of using a content filter to compress CoffeeScript/JS output
# require 'jsmin'
# content_filter do |content, info|
#   if info.ext == '.js'
#     puts "  Compress: #{info.filename}"
#     JSMin.minify content
#   else
#     content
#   end
# end

