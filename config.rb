Honk.setup do
  # You can configure Honk options by changing the values in this file.
  # Just read the comments above each option to learn how to use it.

  # Set the number of posts displayed per page.
  paginate 10

  # Set the folder where you store your files, defaults to the folder where Honk
  # is installed.
  root '.'

  # Defines the post formatter to use. Pass the name of the lib as a symbol, for
  # example :redcloth for the RedCloth gem. If the formatter has a default
  # associated format_proc, this will set it too.
  formatter nil

  # Describe how to format the contents of your post. Pass a proc that takes one
  # string argument and returning a string.
  format_proc { |s| s }

  # A filter for the comments, the default is to HTML-escape the input.
  comment_filter {|s| Rack::Utils.escape_html(s) }

  # Defines metadata for your blog, pass a hash with arbitrary keys.
  # If you customize your views, you can always use Honk.meta[key] to get a
  # metadata.
  # :author, :title, :domain and :email are used with the default views, so you
  # should customize them.
  meta({
    :author => "My name",
    :title => "My blog",
    :domain => "website.com", # no http:// here
    :email => "john@doe.com"
  })

end
