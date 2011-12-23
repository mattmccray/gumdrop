# Any specialized code for your site goes here...

puts "Build: #{Gumdrop.data.config.title} (gumdrop v#{Gumdrop::VERSION})"

if defined? Encoding
  Encoding.default_internal = Encoding.default_external = "UTF-8"
else
  $KCODE = "UTF-8"
end

require 'slim'
Slim::Engine.set_default_options pretty:true

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


# Example site-level generator
# generate do
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
#   
# end
