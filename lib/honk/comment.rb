module Honk
  class Comment
    yaml_as "tag:honk.yapok.org,2009:Comment"

    def yaml_initialize(values={})
      values.each do |k,v|
        instance_variable_set "@#{k}", v
      end
    end

  end
end
