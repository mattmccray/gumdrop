
set :template, "post"

data.blog.each do |post|
  # mdt= Tilt['markdown'].new { post.content }
  # post.body = mdt.render 

  page "#{post.slug}.html", :template=>'post', :post=>post
end

#page "index.html"