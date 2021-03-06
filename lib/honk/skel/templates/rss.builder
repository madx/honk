xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title Honk.options.meta[:title]
    xml.description Honk.options.meta[:description] || Honk.options.meta[:title]
    xml.link blog_url

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.link post_url(post)
        xml.description post.contents
        xml.pubDate post.timestamp.httpdate
        xml.guid post_url(post)
      end
    end
  end
end
