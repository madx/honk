module Honk
  class Index
    yaml_as "tag:honk.yapok.org,2009:Index"

    def yaml_initialize(tag, array)
      raise FileFormatError unless array.is_a?(Array) && array[0].is_a?(Hash)
      @@list = []
      @@mapping = {}
      for entry in array
        @@list << (key = entry.keys.first)
        entry[key] = key + ".yml" if entry[key].nil?
        @@mapping.update(entry)
      end
      raise IndexError if @@list.length != @@mapping.keys.length
    end
  
    class << self
      def has?(name)
        @@list.member?(name)
      end

      def fetch(range)
        raise OutOfRangeError if range.first >= @@list.length 
        @@list[range].collect do |slug|
          Post.open slug, resolve(slug)
        end
      end

      def page(num)
        start = num * Honk.paginate
        fetch start...(start + Honk.paginate)
      end

      def resolve(slug)
        @@mapping[slug]
      end
    end

  end
end
