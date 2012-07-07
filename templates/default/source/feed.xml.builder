xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title config.site.title
  xml.subtitle config.site.tagline
  xml.id config.site.url
  xml.link "href" => config.site.url
  xml.link "href" => "#{config.site.url}/feed.xml", "rel" => "self"
  xml.updated data.news.first.date.to_time.iso8601
  xml.author { xml.name config.site.author }

  site.contents.find("news/**/*").each do |post|
    xml.entry do
      url= "#{config.site.url}/news/#{post._id}-#{post.slug}.html"
      xml.title post.title
      xml.link "rel" => "alternate", "href" => url
      xml.id url
      xml.published post.date.to_time.iso8601
      xml.updated post.date.to_time.iso8601
      xml.author { xml.name config.site.author }
      xml.content render(post), "type" => "html"
    end
  end
end