module Honk
  class Tagging
    yaml_as "tag:honk.yapok.org,2009:Tagging"

    attr_reader :mapping

    def yaml_initialize(tag, mapping)
      initialize mapping
    end

    def initialize(hash)
      @mapping = hash
    end

    def get(tag)
      @mapping[tag] || []
    end

    def has?(tag)
      @mapping.key?(tag)
    end

    def list
      @mapping.keys.sort
    end

    def popular
      @mapping.sort { |a,b|
        a[1].length <=> b[1].length 
      }.reverse.map { |tagging|
        tagging.first
      }
    end
  end
end
