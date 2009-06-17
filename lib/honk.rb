require 'pathname'
require 'yaml'
require 'date'
require 'metash'

class Pathname; alias / join; end

Infinity = 1/0.0

module Honk

  class NoPostError     < StandardError; end
  class IndexError      < StandardError; end
  class OutOfRangeError < StandardError; end
  class FileFormatError < StandardError; end

  DEFAULT_OPTIONS = [
    :root, :paginate, :comment_hook, :comment_filter, :meta, :language
  ]

  DEFAULTS = lambda {
    root           Pathname.new('.').expand_path
    paginate       10
    language       :en
    comment_hook   lambda {|p,c| }
    comment_filter lambda {|s| s }
    meta           _={
      :author      => "Honk default author",
      :title       => "Honk",
      :domain      => "honk.github.com",
      :email       => "honk@nowhere.com",
      :description => "This is a blog"
    }
  }

  @@options = Metash.new
  @@options.instance_eval &DEFAULTS

  def self.setup(&blk)
    @@options.instance_eval &blk
  end

  def self.options
    @@options
  end

  def self.check_options
    validity = true
    messages = {}

    DEFAULT_OPTIONS.each do |opt|
      unless validity &&= !@@options.__send__(opt).nil?
        messages[opt] = "#{opt} is missing"
      end
    end

    if validity
      unless @@options.paginate.is_a?(Numeric)
        messages[:paginate] = 'wrong value for paginate'
      end

      if File.directory?(@@options.root)
        unless File.writable?(@@options.root)
          messages[:root] = "#{@@options.root} is not writable"
        end
      else
        messages[:root] = "#{@@options.root} is not a folder"
      end

      if @@options.comment_filter.is_a?(Proc)
        unless @@options.comment_filter.arity == 1
          messages[:comment_filter] = 'comment_filter takes one argument'
        end
      else
        messages[:comment_filter] = 'comment_filter must be a proc'
      end

      if @@options.comment_hook.is_a?(Proc)
        unless @@options.comment_hook.arity == 2
          messages[:comment_hook] = 'comment_hook takes two arguments'
        end
      else
        messages[:comment_hook] = 'comment_hook must be a proc'
      end

      if @@options.meta.is_a?(Hash)
        missing = []
        [:author, :title, :domain, :email, :description].each do |m|
          missing << m if @@options.meta[m].nil?
        end
        unless missing.empty?
          if missing.size == 1
            messages[:meta] = "missing metadata: #{missing.first}"
          else
            list = "#{missing[0..-2].join(', ')} and #{missing.last}"
            messages[:meta] = "missing metadata: #{list}"
          end
        end
      else
        messages[:meta] = 'meta must be an hash'
      end

      validity = messages.empty?
    end

    {:valid => validity, :messages => messages}
  end

end

%w[post comment index tag].each do |lib|
  require Pathname.new(__FILE__).dirname / 'honk' / lib
end
