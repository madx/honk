%w[rubygems sinatra pathname].each do |lib|
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
require File.join(File.dirname(__FILE__), 'config')

configure do
  set :haml, :attr_wrapper => '"'
end

# Helpers
helpers do
  def partial(name, opts={})
    haml name, opts.merge(:layout => false)
  end

  def tag_link(t)
    partial '%%a{:href => "/tag/%s", :title => "View posts tagged %s"} %s' %
      [t, t, t]
  end

  def post_link(p)
    partial '%%a{:href => "/post/%s", :title => "View this post"} %s' %
      [p.slug, p.title]
  end

  def stylesheet(*names)
    out = ''
    names.each do |name|
      args = {
        :rel => "stylesheet", :type => "text/css",
        :media => "screen", :href => "/css/#{name}.css"
      }
      out << partial("%%link{%s}" % args.inspect)
    end
    out
  end

  def comments_link(post)
    comment_string = "#{post.comments.length} comment"
    comment_string << 's' if post.comments.length != 1
    params = {
      :href => "/post/#{post.slug}#comments",
      :title => 'View comments for this post'
    }
    partial '%%a{%s} %s' % [params.inspect, comment_string]
  end

  def field(name, caption)
    s =  '%%label{:for => "%s"} %s' % [name, caption]
    s << "\n"
    if @errors
        member = @errors.member?(name.to_sym)
      s << '%%input{:type => "text", :name => "%s", :id => "%s", :class => "%s"}'%
        [name, name, member ? 'error' : '']
      if member
        s << "\n"
        s << '%span This field is required'
      end
    else
      s << '%%input{:type => "text", :name => "%s", :id => "%s"}'%
        [name, name]
    end
    partial s
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

post '/post/:name' do
  if Index.has?(params[:name])

    @errors = []
    @errors << :author if params[:author].empty?
    @errors << :email  if params[:email].empty?

    unless @errors.empty?
      begin
        @post = Post.open params[:name], Index.resolve(params[:name])
      rescue Errno::ENOENT
        raise IndexError, params[:name]
      end
      haml :post

    else
      args = {
        :author    => params[:author],
        :email     => params[:email],
        :website   => params[:website].empty? ? nil : params[:website],
        :contents  => Honk.comment_filter.call(
          params[:contents].sanitize_line_ends
        ),
        :timestamp => Time.now
      }

      unless args[:website][0..6] == 'http://'
          args[:website] = "http://#{args[:website]}"
      end

      begin
        comment_file = Index.resolve(params[:name]).
          gsub!(/\.yml$/, '.comments.yml')
      rescue
        raise IndexError, params[:name]
      end

      comment_file = Honk.root / 'posts' / comment_file
      comment = Comment.new args
      File.open(comment_file, 'a') {|f| comment.write(f) }

      redirect request.env['REQUEST_URI']
    end
  else raise NoSuchPost, params[:name] end
end

get '/feed' do
end

get '/_reload' do
  begin
    YAML.load_file(Honk.root / 'index.yml')
    'reloaded.'
  rescue Honk::FileFormatError
    'file format error'
  end
end

get '/css/:stylesheet.css' do
  content_type 'text/css', :encoding => 'utf-8'
  stylesheet = params[:stylesheet] + '.css'
  File.read(File.join(File.dirname(__FILE__), 'css', stylesheet))
end

not_found do
  haml :not_found
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
    be found. Please report this error to the author.
  }
end
