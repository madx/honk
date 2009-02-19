module Honk

  class Post
    yaml_as "tag:honk.yapok.org,2009:Post"    
    attr_reader :title, :tags, :timestamp, :contents, :commentable, :slug

    def yaml_initialize(tag, values)
      values.each do |k,v|
        instance_variable_set "@#{k}", v
      end
    end

    class << self
      def open(slug, file)
        post = YAML.load_file(Honk.root / 'posts' / file)
        post.instance_variable_set "@slug", slug
        post
      end
    end

  end
end
