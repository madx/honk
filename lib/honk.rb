require 'pathname'
require 'yaml'
require 'date'
require 'metash'

class Pathname; alias / join; end

Infinity = 1/0.0

module Honk

  class NoPostError     < StandardError; end
  class IndexError      < StandardError; end
  class OutOfRangeError < StandardError; end
  class FileFormatError < StandardError; end

  DEFAULT_OPTIONS = [
    :root, :paginate, :comment_hook, :comment_filter, :meta, :language
  ]

  DEFAULTS = lambda {
    root           Pathname.new('.').expand_path
    paginate       10
    language       :en
    comment_hook   lambda {|p,c| }
    comment_filter lambda {|s| s }
    meta           _={
      :author      => "Honk default author",
      :title       => "Honk",
      :domain      => "honk.github.com",
      :email       => "honk@nowhere.com",
      :description => "This is a blog"
    }
  }

  @@options = Metash.new
  @@options.instance_eval &DEFAULTS

  def self.setup(&blk)
    @@options.instance_eval &blk
  end

  def self.options
    @@options
  end

  # {{{ Option checking
  def self.check_options
    validity = true
    messages = {}

    DEFAULT_OPTIONS.each do |opt|
      unless validity &&= !@@options.__send__(opt).nil?
        messages[opt] = "#{opt} is missing"
      end
    end

    if validity
      unless @@options.paginate.is_a?(Numeric)
        messages[:paginate] = 'wrong value for paginate'
      end

      if File.directory?(@@options.root)
        unless File.writable?(@@options.root)
          messages[:root] = "#{@@options.root} is not writable"
        end
      else
        messages[:root] = "#{@@options.root} is not a folder"
      end

      if @@options.comment_filter.is_a?(Proc)
        unless @@options.comment_filter.arity == 1
          messages[:comment_filter] = 'comment_filter takes one argument'
        end
      else
        messages[:comment_filter] = 'comment_filter must be a proc'
      end

      if @@options.comment_hook.is_a?(Proc)
        unless @@options.comment_hook.arity == 2
          messages[:comment_hook] = 'comment_hook takes two arguments'
        end
      else
        messages[:comment_hook] = 'comment_hook must be a proc'
      end

      if @@options.meta.is_a?(Hash)
        missing = []
        [:author, :title, :domain, :email, :description].each do |m|
          missing << m if @@options.meta[m].nil?
        end
        unless missing.empty?
          if missing.size == 1
            messages[:meta] = "missing metadata: #{missing.first}"
          else
            list = "#{missing[0..-2].join(', ')} and #{missing.last}"
            messages[:meta] = "missing metadata: #{list}"
          end
        end
      else
        messages[:meta] = 'meta must be an hash'
      end

      validity = messages.empty?
    end

    {:valid => validity, :messages => messages}
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


  # The Comment class represents a single Comment.
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
  #
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
