%w[rubygems sinatra pathname haml].each do |lib|
  require lib
end
require File.join(File.dirname(__FILE__), 'lib', 'honk')

include Honk

class String
  def sanitize_line_ends
    gsub("\r\n", "\n")
  end
end


# Configuration
begin
  require File.join(File.dirname(__FILE__), 'config')
rescue => e
  puts "Configuration error :"
  puts e.message
  exit 1
end

configure do
  set :haml, :attr_wrapper => '"'
end

TEMPLATES = {
  :stylesheet => '%%link{%s}',
  :link       => '%%a{%s} %s',
  :tag_link   => '%%a{:href => "/tag/%s", :title => "View posts tagged %s"} %s',
  :post_link  => '%%a{:href => "/post/%s", :title => "View this post"} %s',
  :label      => '%%label{:for => "%s"} %s:',
  :input      => '%%input{%s}',
  :textarea   => '%%textarea{%s} %s',
  :req_field  => '%%span.error This field is required'
}

# Helpers
helpers do
  def partial(name, opts={})
    haml name, opts.merge(:layout => false)
  end

  def template(name, *args)
    partial TEMPLATES[name] % args
  end

  def tag_link(t)
    template :tag_link, t, t, t
  end

  def post_link(p)
    template :post_link, p.slug, p.title
  end

  def comments_link(post)
    comment_string = "#{post.comments.length} comment"
    comment_string << 's' if post.comments.length != 1
    args = {
      :href => "/post/#{post.slug}#comments",
      :title => 'View comments for this post'
    }
    template :link, args.inspect, comment_string
  end

  def author_mailto_link
    email = Honk.meta[:email].gsub('@', '[REMOVETHIS]@')
    args = {
      :href => "mailto:#{email}", :title => "Send a mail to the author"
    }
    template :link, args.inspect, email
  end

  def label_tag(name, caption)
    template :label, name, caption
  end

  def input_field(name, caption)
    value = params[name.to_sym] || request.cookies[name[2..-1]] || ''
    member = @errors && @errors.member?(name.to_sym)

    args = {
      :type => "text", :name => name, :id => name,
      :class => member ? "error" : "", :value => value
    }

    [
      label_tag(name, caption),
      template(:input, args.inspect),
      field_required(member)
    ].join
  end

  def text_field(name, caption)
    contents = params[name.to_sym] || ''
    member = @errors && @errors.member?(name.to_sym)

    args = {
      :name => name, :id => name, :rows => 15, :cols => 50,
      :class => member ? "error" : ""
    }

    [
      label_tag(name, caption),
      template(:textarea, args.inspect, contents),
      field_required(member)
    ].join
  end

  def remember_check_box
    args = {
      :name => "c_remember", :id => "c_remember",
      :type => "checkbox"
    }
    if request.cookies["remember"] then args["checked"] = "checked" end
    template :input, args.inspect
  end

  def stylesheet(name)
    args = {
      :rel => "stylesheet", :type => "text/css",
      :media => "screen", :href => versioned_css("/css/#{name}.css")
    }
    template :stylesheet, args.inspect
  end

  def versioned_css(file)
    mtime = File.mtime(File.join(File.dirname(__FILE__), file)).to_i
    "%s?%s" % [file, mtime]
  end

  def field_required(member)
    member ? template(:req_field) : ''
  end

  def tag_url(t)
    "http://" + File.join(Honk.meta[:domain], 'tag', t)
  end

  def post_url(p)
    "http://" + File.join(Honk.meta[:domain], 'post', p.slug)
  end

  def blog_url
    "http://" + Honk.meta[:domain] + '/'
  end

  def tag_item_count(items)
    len = items.length
    len == 1 ? "#{len} item" : "#{len} items"
  end
end

# Errors
class NoSuchPost < NameError; end
class NoSuchTag  < NameError; end

# Load the index and tags file
YAML.load_file(Honk.root / 'index.yml')
YAML.load_file(Honk.root / 'tags.yml')

# --- Main app starts here ---

get '/' do
  page_num = params[:page].to_i || 0
  @posts = Index.page page_num
  @page = Index.pages(@posts.first.slug)
  haml :index
end

get '/post/:name' do
  if Index.has?(params[:name])
    begin
      @post = Post.open params[:name], Index.resolve(params[:name])
    rescue Errno::ENOENT
      raise IndexError, params[:name]
    end
    haml :post
  else raise NoSuchPost, params[:name] end
end

get '/tag/:tag' do
  if Tag.exists?(params[:tag])
    @posts = Tag.get(params[:tag]).collect do |post|
      Post.open(post, Index.resolve(post))
    end
    haml :tag
  else raise NoSuchTag, params[:tag] end
end

get '/tags' do
  @tags = Tag.sorted_list
  haml :tags
end

get '/archive' do
  @posts = Index.all
  haml :archive
end

post '/post/:name' do
  if Index.has?(params[:name])
    unless params[:c_nickname].strip.empty?
      redirect '/'
    end

    @errors = []
    @errors << :c_author   if params[:c_author].strip.empty?
    @errors << :c_email    if params[:c_email].strip.empty?
    if params[:c_contents].empty? || params[:c_contents] =~ /\A\s+\Z/
      @errors << :c_contents
    end

    unless @errors.empty?
      begin
        @post = Post.open params[:name], Index.resolve(params[:name])
      rescue Errno::ENOENT
        raise IndexError, params[:name]
      end
      haml :post

    else
      post = Post.open params[:name], Index.resolve(params[:name])
      args = {
        :author    => params[:c_author],
        :email     => params[:c_email],
        :website   => params[:c_website],
        :contents  => Honk.comment_filter.call(
          params[:c_contents].sanitize_line_ends
        ),
        :timestamp => Time.now
      }

      unless args[:website][0..6] == 'http://'
        args[:website] = "http://#{args[:website]}"
      end
      args[:website] = nil if args[:website].empty?

      if params[:c_remember]
        [:author, :email, :website].each do |field|
          response.set_cookie(field.to_s, :value => args[field])
        end
        response.set_cookie("remember", true)
      else
        [:author, :email, :website].each do |field|
          response.delete_cookie(field.to_s)
        end
        response.delete_cookie("remember")
      end

      begin
        comment_file = Index.resolve(params[:name]).
          gsub(/\.yml$/, '.comments.yml')
      rescue
        raise IndexError, params[:name]
      end

      comment_file = Honk.root / 'posts' / comment_file
      comment = Comment.new args
      File.open(comment_file, 'a') {|f| comment.write(f) }

      Honk.post_comment_hook.call(post, comment)

      redirect request.env['REQUEST_URI']
    end
  else raise NoSuchPost, params[:name] end
end

get '/atom.xml' do
  @posts = Index.page 0
  builder :atom
end

get '/rss.xml' do
  @posts = Index.page 0
  builder :rss
end

get '/_sync' do
  begin
    YAML.load_file(Honk.root / 'index.yml')
    begin
      YAML.load_file(Honk.root / 'tags.yml')
    rescue Honk::FileFormatError
      'tags file format error'
    end
    'reloaded.'
  rescue Honk::FileFormatError
    'index file format error'
  end
end

get '/css/:stylesheet.css' do
  content_type 'text/css', :encoding => 'utf-8'
  stylesheet = params[:stylesheet] + '.css'
  response['Expires'] = (Time.now + 60*60*24*365*3).httpdate
  File.read(File.join(File.dirname(__FILE__), 'css', stylesheet))
end

not_found do
  haml :not_found
end

configure :production do
  error do
    haml :error
  end
end

error Honk::OutOfRangeError do
  @message = "There are not that many posts on this blog!"
  haml :not_found
end

error NoSuchPost do
  @message = %Q{
    There's no such post <strong>#{request.env['sinatra.error'].message}</strong>.
  }
  haml :not_found
end

error NoSuchTag do
  @message = %Q{
    There's no such tag <strong>#{request.env['sinatra.error'].message}</strong>.
    <br />
    Maybe you can search on <a href="/tags" title="View the tag list">the tags
    page</a>.
  }
  haml :not_found
end

error IndexError do
  @message = %Q{
    The file associated with #{request.env['sinatra.error'].message} couldn't
    be found.
  }
  haml :error
end
