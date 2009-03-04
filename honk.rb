%w[rubygems sinatra pathname].each do |lib|
  require lib
end
require File.join(File.dirname(__FILE__), 'lib', 'honk') 

include Honk

class String
  def sanitize_line_ends!
    gsub!("\r\n", "\n")
  end
end


# Configuration
Honk.setup do
  comment_filter { |s|
    Haml::Helpers.html_escape s
  }
end

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

  def comments_link(post)
    comment_string = "#{post.comments.length} comment"
    comment_string << 's' if post.comments.length != 1
    params = {
      :href => "/post/#{post.slug}#comments",
      :title => 'View comments for this post'
    }
    partial '%%a{%s} %s' % [params.inspect, comment_string]
  end

  def field(name, caption, required = true)
    s =  '%%label{:for => "%s"} %s' % [name, caption]
    s << "\n"
    s << '%%input{:type => "text", :name => "%s", :id => "%s", :class => "%s"}'%
      [name, name, required ? 'required' : 'optional' ]
    partial s
  end
end

# Errors
class CommentFieldError < ArgumentError; end

# Load the index file
YAML.load_file(Honk.root / 'index.yml')

# --- Main app starts here ---

get '/' do
  page_num = params[:page].to_i || 0
  begin
    @posts = Index.page page_num
  rescue Honk::OutOfRangeError
    raise Sinatra::NotFound
  end
  haml :index 
end

get '/post/:name' do
  if Index.has?(params[:name])
    begin
      @post = Post.open params[:name], Index.resolve(params[:name])
    rescue Errno::ENOENT
      raise Sinatra::NotFound
    end
    haml :post
  else raise Sinatra::NotFound end
end

post '/post/:name' do
  if Index.has?(params[:name])
    args = {
      :author      => params[:author],
      :email     => params[:email],
      :website   => params[:website].empty? ? nil : params[:website],
      :contents  => Honk.comment_filter.call(
        params[:contents].sanitize_line_ends!
      ),
      :timestamp => Time.now
    }
    unless args[:website][0..6] == 'http://'
        args[:website] = "http://#{args[:website]}"
    end
    args.inspect.gsub('<', '&lt;').gsub('>', '&gt;')
  else raise Sinatra::NotFound end
end

get '/feed' do
end

get '/_reload' do
  YAML.load_file(Honk.root / 'index.yml')
  'reloaded.'
end
