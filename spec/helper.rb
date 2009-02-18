require File.join(File.dirname(__FILE__), '..', 'lib', 'honk')

def reset_honk
  Honk.setup {
    root File.join(File.dirname(__FILE__), 'mock')
    paginate 10
    formatter nil
    format_proc {|s| s }
  }
end

reset_honk

include Honk
