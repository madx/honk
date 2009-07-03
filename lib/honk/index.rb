module Honk
  class Index

    @@tag = "tag:honk.yapok.org,2009:Index"
    yaml_as @@tag

    attr_reader :list, :map

    def initialize(array)
      populate_attributes array
    end

    def yaml_initialize(tag, array)
      populate_attributes array
    end

    def has?(entry)
      @list.member? entry
    end

    def fetch(range)
      if range.first >= @list.length
        raise IndexError, "first item is out of range"
      end
      @list[range].collect do |slug|
        Post.open slug, map[slug]
      end
    end

    def all
      fetch 0..(@list.length)
    end

    def pages
      @list.length / Honk.options.paginate
    end

    def page(n)
      return all if Honk.options.paginate == Infinity
      start = n * Honk.options.paginate
      fetch start...(start + Honk.options.paginate)
    end

    def dump
      YAML.quick_emit(object_id, {}) do |out|
        out.seq(@@tag, to_yaml_style) do |seq|
          @list.each do |k|
            seq.add({k => map[k]})
          end
        end
      end
    end

    def push(slug, name=nil)
      raise IndexError, "#{slug} is already in the index" if @list.member?(slug)
      name = expand_tildes(slug, name)
      @list << slug
      @map[slug] = name
    end

    private

    def populate_attributes(array)
      @list = []
      @map  = {}

      for entry in array
        push(entry.keys.first, entry[entry.keys.first])
      end
    end

    def expand_tildes(slug, file)
      if file.nil?
        file = "#{slug}.yml"
      end
      file.gsub('~', slug)
    end

  end
end
