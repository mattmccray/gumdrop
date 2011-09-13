# Any specialized code for your site goes here...

puts "Build: #{Gumdrop.data.config.title} (gumdrop v#{Gumdrop::VERSION})"

if defined? Encoding
  Encoding.default_internal = Encoding.default_external = "UTF-8"
else
  $KCODE = "UTF-8"
end

require 'slim'
Slim::Engine.set_default_options :pretty => true

# Example site-level generator
# generate do
#
#   page "about.html", :template=>'about', :passthru=>'Available in the template' # requires a about.template.XX file
#   
#   # Maybe for a tumblr-like pager
#   pager= Gumdrop.data.pager_for :posts, :base_path=>'posts/page', :page_size=>5
#   pager.each do |page|
#     page "#{page.uri}.html", :template=>'post_page', :posts=>page.items, :pager=>pager, :current_page=>pager.current_page
#   end
#   
# end