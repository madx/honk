module Honk

  class Post
    yaml_as "tag:honk.yapok.org,2009:Post"    
    attr_reader :title, :tags, :timestamp, :contents, :commentable, :slug,
                :comments

    def yaml_initialize(tag, values)
      values.each do |k,v|
        instance_variable_set "@#{k}", v
      end
    end
    
    def comments
      if @comments.nil?
        begin
          comment_file = Honk.root / 'posts' / "#@slug.comments.yml"
          if File.exist? comment_file
            docs = YAML.load_stream(File.read(comment_file)).documents
            if docs.inject(true) {|b,d| b &&= d.is_a?(Comment) }
              @comments = docs
            else
              puts "File format error for #{comment_file}"
              raise FileFormatError
            end
          else 
            [] 
          end
        rescue NoMethodError, FileFormatError
          []
        end
      else 
        @comments 
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
