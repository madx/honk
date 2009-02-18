module Honk

  class Post
    yaml_as "tag:honk.yapok.org,2009:Post"    
    attr_reader :title, :tags, :timestamp, :contents, :commentable

    def yaml_initialize(tag, values)
      values.each do |k,v|
        instance_variable_set "@#{k}", v
      end
    end

    class << self
      def open(file)
        YAML.load_file(Honk.root / 'posts' / file)
      end
    end

  end
end
