# vim:ft=ruby
require 'rack/utils'
require 'fileutils'

this = File.dirname(__FILE__)
require File.join(this, 'lib', 'honk')
require File.join(this, 'config')

class Script < Thor

  desc "bootstrap", "create the default files"
  method_options :root => :optional
  def bootstrap
    puts "Creating directories..."
    FileUtils.mkdir_p Honk.root unless File.exist? Honk.root
    FileUtils.mkdir   Honk.root/'posts' unless File.exist? Honk.root/'posts'

    puts "Creating default files..."
    File.open(Honk.root/'index.yml', 'w+') do |f|
      f.puts "--- !honk.yapok.org,2009/Index"
    end
    File.open(Honk.root/'tags.yml', 'w+') do |f|
      f.puts "--- !honk.yapok.org,2009/Tags"
    end
    puts "Finished."
  end

end
