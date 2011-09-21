xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title data.config.title
  xml.subtitle data.config.tagline
  xml.id data.config.url
  xml.link "href" => data.config.url
  xml.link "href" => "#{data.config.url}/feed.xml", "rel" => "self"
  xml.updated data.blog.first.date.to_time.iso8601
  xml.author { xml.name data.config.author }

  data.blog.each do |post|
    xml.entry do
      url= "#{data.config.url}/posts/#{post.slug}"
      xml.title post.title
      xml.link "rel" => "alternate", "href" => url
      xml.id url
      xml.published post.date.to_time.iso8601
      xml.updated post.date.to_time.iso8601
      xml.author { xml.name data.config.author }
      xml.content post.body, "type" => "html"
    end
  end
end