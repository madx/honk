require File.join(File.dirname(__FILE__), '..', 'lib', 'honk')
require 'bacon'

def reset_honk
  Honk.setup {
    root File.join(File.dirname(__FILE__), 'mock')
    paginate 10
  }
end

reset_honk
