module Honk
  class Index
    yaml_as "tag:honk.yapok.org,2009:Index"

    def yaml_initialize(tag, array)
      raise IndexError unless array.is_a?(Array) && array[0].is_a?(Hash)
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
        if range.first >= @@list.length || range.to_a.last >= @@list.length
          raise OutOfRangeError
        end
        @@list[range].collect do |name|
          Post.open resolve(name)
        end
      end

      def resolve(name)
        @@mapping[name]
      end
    end

  end
end
