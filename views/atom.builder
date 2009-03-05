author = lambda {
  xml.name Honk.meta[:author]
  xml.email Honk.meta[:email]
  xml.uri blog_url
}

xml.instruct! :xml, :version => "1.0"
p request.env
xml.feed :xmlns => "http://www.w3.org/2005/Atom" do
  xml.id blog_url 
  xml.title Honk.meta[:title]
  xml.updated @posts.first.timestamp.httpdate
  xml.link :href => blog_url
  xml.link :rel => "self", :href => File.join(blog_url, request.env["REQUEST_URI"])
  xml.author &author

  @posts.each do |post|
    xml.entry do
      xml.id post_url(post)
      xml.title post.title, :type => "html"
      xml.updated post.timestamp.httpdate
      xml.author &author
      xml.link post_url(post), :rel => "alternate"
      xml.summary :type => "xhtml" do
        xml.div :xmlns => "http://www.w3.org/xhtml" do
          xml << post.contents
        end
      end
      post.tags.each do |tag|
        xml.category :term => tag, :scheme => tag_url(tag)
      end
    end
  end
end
