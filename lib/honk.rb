%w[pathname yaml date metash sinatra/base haml mime/types].each do |lib|
  require lib
end

class Pathname; alias / join; end

Infinity = 1/0.0

module Honk
  PATH = Pathname.new(__FILE__).dirname

  class IndexError    < StandardError; end
  class NoTagError    < StandardError; end
  class NoPostError   < StandardError; end
  class SecurityError < StandardError; end

  DEFAULT_OPTIONS = [
    :root, :paginate, :comment_hook, :comment_filter, :meta, :time_format
  ]

  DEFAULTS = lambda {
    root           PATH / 'honk' / 'skel'
    paginate       10
    language       :en
    comment_hook   lambda {|p,c| }
    comment_filter lambda {|s| s }
    time_format    '%c'
    meta           _={
      :author      => "Honk default author",
      :title       => "Honk",
      :domain      => "honk.github.com",
      :email       => "honk@nowhere.com",
      :description => "This is a blog"
    }
  }

  @@options = Metash.new
  @@options.instance_eval(&DEFAULTS)

  @@index, @@tags = nil, nil

  def self.setup(&blk)
    @@options.instance_eval(&blk)
  end

  def self.options
    @@options
  end

  def self.load!
    @@index = YAML.load_file(options.root / 'index.yml')
    @@tags  = YAML.load_file(options.root / 'tags.yml')
  end

  def self.index; @@index; end
  def self.tags;  @@tags;  end

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

      if @@options.root.is_a?(Pathname)
        if @@options.root.directory?
          unless @@options.root.writable?
            messages[:root] = "#{@@options.root} is not writable"
          end
        else
          messages[:root] = "#{@@options.root} is not a folder"
        end
      else
        messages[:root] = "#{@@options.root.inspect} is not a Pathname"
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

%w[post comment index tagging helpers].each do |lib|
  require Honk::PATH / 'honk' / lib
end
