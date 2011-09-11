# Any specialized code for your site goes here...

puts "Building: #{Gumdrop.data.config.title}"

new_posts= Gumdrop.data.posts.map do |post|
  mdt= Tilt['markdown'].new { post.content }
  post.body = mdt.render
  post
end

Gumdrop.data.set :blog, new_posts, :persist=>true


generate do
  
  page "my-root-page.html", :template=>'test', :info=>"FROM SITE.RB"
  
  pager= Gumdrop.data.pager_for :blog, :base_path=>'posts/page', :page_size=>1
  
  pager.each do |pageset|
    page "#{pageset.uri}.html", :template=>'post_page', :posts=>pageset.items, :pager=>pager, :current_page=>pager.current_page
  end
  
end
