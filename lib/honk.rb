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
    :comment_filter => lambda {|s| s },
    :meta        => {
      :author => "Honk default author",
      :title  => "Honk",
      :domain => "honk.github.com",
      :email  => "honk@nowhere.com"
    }
  }

  @@config = DEFAULTS.dup

  def self.setup(&blk)
    instance_eval &blk
  end

  def self.config
    @@config
  end

  def self.paginate(count=nil)
    count ? @@config[:paginate] = count : @@config[:paginate]
  end

  def self.root(path=nil)
    path ? @@config[:root] = Pathname.new(path).expand_path : @@config[:root]
  end

  def self.meta(hash=nil)
    hash ? @@config[:meta].update(hash) : @@config[:meta]
  end

  def self.comment_filter(&blk)
    if block_given?
      raise ArgumentError if blk.arity != 1
      @@config[:comment_filter] = blk
    else
      @@config[:comment_filter]
    end
  end

end

%w[comment index post tag].each do |file|
  require Pathname.new(__FILE__).dirname / 'honk' / file
end
