module Honk
  class Post
    yaml_as "tag:honk.yapok.org,2009:Post"

    attr_accessor :title, :timestamp, :contents, :commentable, :abstract,
                  :tags, :slug, :file

    def yaml_initialize(tag, params)
      initialize_attributes params
    end

    def initialize(params={})
      params[:timestamp] ||= Time.now
      initialize_attributes params
    end

    def comments
      if @comments.nil?
        begin
          comment_file = Honk.options.root / 'posts' /
                         @file.gsub(/\.yml$/, '.comments.yml')
          if File.exist? comment_file
            @comments = YAML.load_stream(File.read(comment_file)).documents
          else [] end
        rescue NoMethodError
          []
        end
      else @comments end
    end

    def to_yaml_properties
      %w[@title @tags @timestamp @commentable @abstract @contents]
    end

    def formatted_timestamp
      @timestamp.strftime Honk.options.time_format
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

    def self.open(slug, file)
      path = Honk.options.root / 'posts' / file
      post = YAML.load_file(path)
      post.tap do |p|
        p.slug = slug
        p.file = file
        p.timestamp ||= path.mtime
      end
    end

    private

    def initialize_attributes(params={})
      raise ArgumentError, 'title is missing'     unless params[:title]
      raise ArgumentError, 'contents are missing' unless params[:contents]

      unless params[:timestamp].is_a? Time
        params[:timestamp] = Time.parse(params[:timestamp])
      end

      params[:commentable] ||= true
      params[:tags]        ||= []

      params.each do |key, value|
        instance_variable_set "@#{key}", value
      end
    end

  end
end
