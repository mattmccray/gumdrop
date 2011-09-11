# Any specialized code for your site goes here...

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