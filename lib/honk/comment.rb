module Honk
  class Comment
    yaml_as "tag:honk.yapok.org,2009:Comment"

    attr_reader :author, :email, :website, :timestamp, :contents

    def yaml_initialize(tag, values)
      values.each do |k,v|
        instance_variable_set "@#{k}", v
      end
    end

  end
end
