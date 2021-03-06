module Honk
  class Comment
    yaml_as "tag:honk.yapok.org,2009:Comment"

    attr_reader   :author, :email, :website, :timestamp, :contents
    attr_accessor :spam

    def yaml_initialize(tag, params)
      initialize params
    end

    def initialize(params={})
      params[:timestamp] ||= Time.now
      raise ArgumentError, 'author is missing'    unless params[:author]
      raise ArgumentError, 'email is missing'     unless params[:email]
      raise ArgumentError, 'contents are missing' unless params[:contents]

      params[:website] ||= ""
      params[:spam]    ||= false

      params.each do |k,v|
        instance_variable_set "@#{k}", v
      end
    end

    def to_yaml_properties
      %w[@author @email @website @timestamp @spam @contents]
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

  end
end
