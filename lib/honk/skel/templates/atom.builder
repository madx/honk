author = lambda {
  xml.name Honk.options.meta[:author]
  xml.email Honk.options.meta[:email]
  xml.uri blog_url
}

xml.instruct! :xml, :version => "1.0"
xml.feed :xmlns => "http://www.w3.org/2005/Atom" do
  xml.id blog_url
  xml.title Honk.options.meta[:title]
  xml.updated @posts.first.timestamp.xmlschema
  xml.link :href => blog_url
  xml.link :rel => "self", :href => File.join(blog_url, 'atom.xml')
  xml.author &author

  @posts.each do |post|
    xml.entry do
      xml.id post_url(post)
      xml.title post.title, :type => "html"
      xml.updated post.timestamp.xmlschema
      xml.author &author
      xml.link :rel => "alternate", :href => post_url(post)
      xml.summary :type => "xhtml" do
        xml.div :xmlns => "http://www.w3.org/1999/xhtml" do
          xml << post.contents
        end
      end
      post.tags.each do |tag|
        xml.category :term => tag, :scheme => tag_url(tag)
      end
    end
  end
end
