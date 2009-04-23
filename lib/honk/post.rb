module Honk

  class Post
    yaml_as "tag:honk.yapok.org,2009:Post"    
    attr_accessor :title, :tags, :timestamp, :contents, :commentable, :slug,
                  :file, :comments

    def yaml_initialize(tag, values)
      raise FileFormatError, "not a valid Post" unless values.is_a? Hash
      values.each do |k,v|
        instance_variable_set "@#{k}", v
      end
      @timestamp = Time.parse(@timestamp) unless @timestamp.is_a?(Time)
    end

    def initialize(params={})
      params.each do |k,v|
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

    def to_yaml_properties
      %w[@title @tags @timestamp @commentable @contents]
    end

    def to_yaml(opts)
      YAML.quick_emit(object_id, opts) do |out|
        out.map(taguri, to_yaml_style) do |map|
          to_yaml_properties.each do |field|
            map.add(field[1..-1].to_sym, instance_variable_get(field))
          end
        end
      end                  
    end

    def write(fileish)
      fileish << YAML.dump(self)
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
