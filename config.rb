Honk.setup do
  # You can configure Honk options by changing the values in this file.
  # Just read the comments above each option to learn how to use it.

  # Set the number of posts displayed per page.
  # Set to Infinity to disable pagination (all posts on the same page).
  paginate 10

  # Set the folder where you store your files, defaults to the current folder.
  root '.'

  # A filter for the comments, the default is to HTML-escape the input.
  comment_filter {|s| Rack::Utils.escape_html(s) }

  # Defines metadata for your blog, pass a hash with arbitrary keys.
  # If you customize your views, you can always use Honk.meta[key] to get a
  # metadata.
  # :author, :title, :domain and :email are used with the default views, so you
  # should customize them (and you shouldn't remove them!).
  meta({
    :author => "My name",
    :title => "My blog",
    :domain => "website.com", # no http:// here
    :email => "john@doe.com"
  })

end
