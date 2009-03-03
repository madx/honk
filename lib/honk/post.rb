module Honk

  class Post
    yaml_as "tag:honk.yapok.org,2009:Post"    
    attr_reader :title, :tags, :timestamp, :contents, :commentable, :slug,
                :file, :comments

    def yaml_initialize(tag, values)
      raise FileFormatError, "not a valid Post" unless values.is_a? Hash
      values.each do |k,v|
        instance_variable_set "@#{k}", v
      end
    end
    
    def comments
      if @comments.nil?
        begin
          comment_file = Honk.root / 'posts' / @file.gsub(/\.yml$/, '.comments.yml')
          if File.exist? comment_file
            @comments = YAML.load_stream(File.read(comment_file)).documents
          else [] end
        rescue NoMethodError, FileFormatError
          []
        end
      else @comments end
    end

    class << self
      def open(slug, file)
        post = YAML.load_file(Honk.root / 'posts' / file)
        raise FileFormatError unless post.is_a?(Post)
        post.instance_variable_set "@slug", slug
        post.instance_variable_set "@file", file
        post
      end
    end

  end
end
