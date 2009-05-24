xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title Honk.meta[:title]
    xml.description Honk.meta[:description] || Honk.meta[:title]
    xml.link blog_url

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.link post_url(post)
        xml.description Honk.format_proc.call(post.contents)
        xml.pubDate post.timestamp.httpdate
        xml.guid post_url(post)
      end
    end
  end
end
