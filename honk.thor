# vim:ft=ruby
require 'rack/utils'
require 'fileutils'

this = File.dirname(__FILE__)
require File.join(this, 'lib', 'honk')
require File.join(this, 'config')

class Blog < Thor

  desc "bootstrap", "create the default files"
  method_options :root => :optional
  def bootstrap
    if options[:root]
      Honk.root options[:root]
    end
    puts "Creating directories..."
    if File.exist?(Honk.root) && Dir.entries(Honk.root) != %w[. ..]
      puts "root directory is not empty, aborting."
      exit 1
    end
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
    puts <<EOT
Put your posts in #{Honk.root/'posts'}.
Edit the index.yml and tags.yml files accordingly.
EOT
  end

end
