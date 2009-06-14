require 'pathname'
require 'yaml'
require 'date'

class Pathname; alias / join; end

Infinity = 1/0.0

module Honk

  class NoPostError     < StandardError; end
  class IndexError      < StandardError; end
  class OutOfRangeError < StandardError; end
  class FileFormatError < StandardError; end

  DEFAULTS = {
    :paginate       => 10,
    :root           => Pathname.new('.').expand_path,
    :comment_filter => lambda {|s| s },
    :post_comment_hook => lambda {|p,c| },
    :meta        => {
      :author      => "Honk default author",
      :title       => "Honk",
      :domain      => "honk.github.com",
      :email       => "honk@nowhere.com",
      :description => "This is a blog"
    }
  }

  @@config = DEFAULTS.dup

  # {{{ Module methods
  class << self
    def setup(&blk)
      instance_eval &blk
    end

    def config
      @@config
    end

    def paginate(count=nil)
      count ? @@config[:paginate] = count : @@config[:paginate]
    end

    def root(path=nil)
      if path
        pn = Pathname.new(path).expand_path
        if pn.exist?
          @@config[:root] = pn
        else
          raise "No such directory #{pn}"
        end
      else
        @@config[:root]
      end
    end

    def meta(hash=nil)
      hash ? @@config[:meta].update(hash) : @@config[:meta]
    end

    def comment_filter(&blk)
      if block_given?
        if blk.arity != 1
          raise "The comment_filter block should take one argument"
        end
        @@config[:comment_filter] = blk
      else
        @@config[:comment_filter]
      end
    end

    def post_comment_hook(&blk)
      if block_given?
        if blk.arity != 2
          raise "The post_comment_hook block should take two arguments"
        end
        @@config[:post_comment_hook] = blk
      else
        @@config[:post_comment_hook]
      end
    end
  end # }}}

  # The Post class represents a single Post.
  # {{{
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
      [:title, :timestamp, :contents, :commentable, :tags].each do |param|
        params[param] ||= nil
        instance_variable_set "@#{param}", params[param]
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

    def self.open(slug, file)
      post = YAML.load_file(Honk.root / 'posts' / file)
      raise FileFormatError unless post.is_a?(Post)
      post.tap do |p|
        p.slug = slug
        p.file = file
      end
    end

  end # }}}

  # {{{
  class Comment
    yaml_as "tag:honk.yapok.org,2009:Comment"

    attr_reader :author, :email, :website, :timestamp, :contents, :post

    def yaml_initialize(tag, values)
      raise FileFormatError, "not a valid comment" unless values.is_a? Hash
      initialize(values)
    end

    def initialize(params={})
      params.each do |k,v|
        instance_variable_set "@#{k}", v
      end
    end

    def to_yaml_properties
      %w[@author @email @website @timestamp @contents]
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

  end # }}}

  # {{{
  class Index
    yaml_as "tag:honk.yapok.org,2009:Index"

    def yaml_initialize(tag, array)
      @@tag = tag
      unless array.is_a?(Array) && array.inject(true) {|b,e| e.is_a?(Hash) }
        raise FileFormatError, "not a valid index"
      end
      @@list = []
      @@map = {}
      for entry in array
        @@list << (key = entry.keys.first)
        if !entry[key]
          entry[key] = "#{key}.yml"
        elsif entry[key].index '~'
          entry[key].gsub! '~', key
        end
        @@map.update(entry)
      end
      raise IndexError if @@list.length != @@map.keys.length
    end


    class << self
      def dump
        YAML.quick_emit(object_id, {}) do |out|
          out.seq(@@tag, to_yaml_style) do |seq|
            @@list.each do |k|
              seq.add({k, @@map[k]})
            end
          end
        end
      end

      def has?(name)
        @@list.member?(name)
      end

      def list
        @@list
      end

      def map
        @@map
      end

      def fetch(range)
        raise OutOfRangeError if range.first >= @@list.length
        @@list[range].collect do |slug|
          Post.open slug, resolve(slug)
        end
      end

      def page(num)
        return all if Honk.paginate == Infinity
        start = num * Honk.paginate
        fetch start...(start + Honk.paginate)
      end

      def all
        fetch 0...(@@list.length)
      end

      def pages(slug=nil)
        (@@list.index(slug) || @@list.length) / Honk.paginate
      end

      def resolve(slug)
        @@map[slug]
      end

      def push(map)
        key = map.keys.first
        unless @@list.member?(key)
          @@map.update(map)
          @@list.unshift(key)
        end
      end
    end # class methods
  end # }}}

    # {{{
  class Tag
    yaml_as "tag:honk.yapok.org,2009:Tags"

    def yaml_initialize(tag, mapping)
      unless mapping.is_a?(Hash) &&
             mapping.keys.inject(true) {|b,k| mapping[k].is_a?(Array)}
        raise FileFormatError
      end
      @@mapping = mapping
    end

    class << self
      def get(name)
        @@mapping[name] || []
      end

      def exists?(tag)
        @@mapping.key?(tag)
      end

      def tags
        @@mapping.keys.sort
      end

      def sorted_list
        @@mapping.sort {|a,b| a[1].length <=> b[1].length }.reverse
      end
    end

  end # }}}

end # Honk
