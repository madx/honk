module Honk
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
  end
end
