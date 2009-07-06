require 'honk'
require Honk::PATH / 'honk' / 'app'

# Configure Honk here
Honk.setup do
  # You can configure Honk options by changing the values in this file.
  # Just read the comments above each option to learn how to use it.

  # Set the number of posts displayed per page.
  # Set to Infinity to disable pagination (all posts on the same page).
  paginate 10

  # Set the folder where you store your files, defaults to the current folder.
  root Pathname.new(__FILE__).dirname

  # A filter for the comments, the default is to HTML-escape the input.
  comment_filter {|s| Rack::Utils.escape_html(s) }

  # A hook that is called after successfuly posting a comment
  post_comment_hook { |post, comment|
  }

  # Define your time format (see Time#srtftime for available formats)
  # time_format '%c'

  # Defines metadata for your blog, pass a hash with arbitrary keys.
  # If you customize your views, you can always use Honk.meta[key] to get a
  # metadata.
  # :author, :title, :domain and :email are used with the default views, so you
  # should customize them (and you shouldn't remove them!).
  # meta({
  #   :author => "My name",
  #   :title => "My blog",
  #   :domain => "website.com", # no http:// here
  #   :email => "john@doe.com",
  #   :description => "This is a blog"
  # })

end

if (hp = Honk.options.root / 'helpers.rb').exist?
  puts "Loading custom helpers..."
  require hp
  Honk::App.helpers Honk::Helpers
end

puts "Checking options..."
check = Honk.check_options

if check[:valid]
  puts <<-eof
Configuration:
  paginate: #{Honk.options.paginate}
  root:     #{Honk.options.root}
  meta:
    author: #{Honk.options.meta[:author]}
    title:  #{Honk.options.meta[:title]}
    domain: #{Honk.options.meta[:domain]}
    email:  #{Honk.options.meta[:email]}
    description: #{Honk.options.meta[:description]}
  eof

else
  check[:messages].each do |opt, message|
    puts "Error in option #{opt}: #{message}"
  end
  exit 1

end

puts "Let's rock!"

run Honk::App
# vim: set ft=ruby:
