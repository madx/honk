require 'pathname'
require 'yaml'
require 'date'

class Pathname; alias / join; end

module Honk

  class NoPostError     < StandardError; end
  class IndexError      < StandardError; end
  class OutOfRangeError < StandardError; end
  class FileFormatError < StandardError; end

  DEFAULTS = {
    :paginate       => 10,
    :root           => Pathname.new('.').expand_path,
    :formatter      => nil,
    :format_proc    => lambda {|s| s },
    :comment_filter => lambda {|s| s },
    :meta        => {
      :author => "Honk default author",
      :title  => "Honk",
      :domain => "honk.github.com",
      :email  => "honk@nowhere.com"
    }
  }

  FORMAT_PROCS = {
    :redcloth => lambda { |s|
      rc = RedCloth.new(s)
      rc.hard_breaks = false
      rc.to_html
    }
  }

  @@config = DEFAULTS.dup

  class << self
    def setup(&blk)
      instance_eval &blk
    end
    
    def config
      @@config
    end

    def paginate(count=nil)
      count ? @@config[:paginate] = count : @@config[:paginate]
    end

    def root(path=nil)
      path ? @@config[:root] = Pathname.new(path).expand_path : @@config[:root]
    end

    def meta(hash=nil)
      hash ? @@config[:meta] = hash : @@config[:meta]
    end

    def format_proc(&blk)
      if block_given? 
        raise ArgumentError if blk.arity != 1
        @@config[:format_proc] = blk 
      else 
        @@config[:format_proc] 
      end
    end

    def comment_filter(&blk)
      if block_given? 
        raise ArgumentError if blk.arity != 1
        @@config[:comment_filter] = blk 
      else 
        @@config[:comment_filter] 
      end
    end

    def formatter(name=nil)
      if name
        @@config[:formatter] = name
        @@config[:format_proc] = FORMAT_PROCS[name] || DEFAULTS[:format_proc]
        begin
          require name.to_s
        rescue LoadError
          $stderr.puts "Unable to load formatter #{name}. Aborting."
          exit 1
        end
      else
        @@config[:formatter]
      end
    end
  end

end

%w[comment index post tag].each do |file|
  require Pathname.new(__FILE__).dirname / 'honk' / file
end
