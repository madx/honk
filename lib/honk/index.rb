module Honk
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
  end
end
