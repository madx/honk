%w[rubygems sinatra pathname].each do |lib|
  require lib
end
require File.join(File.dirname(__FILE__), 'lib', 'honk') 
include Honk

# configuration
Honk.setup do
  comment_filter { |s|
    Haml::Helpers.html_escape s
  }
end

configure do
  set :haml, :attr_wrapper => '"'
end

class String
  def sanitize_line_ends!
    gsub!("\r\n", "\n")
  end
end

YAML.load_file(Honk.root / 'index.yml')

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
  else
    raise Sinatra::NotFound
  end
end

post '/post/:name' do
  if params['website'].empty?
    params['website'] = nil
  else
    unless params['website'][0..6] == 'http://'
      params['website'] = "http://#{params['website']}"
    end
  end
  params['contents'].sanitize_line_ends!
  params.inspect.gsub('<', '&lt;').gsub('>', '&gt;')
end

get '/feed' do
end

get '/_reload' do
  YAML.load_file(Honk.root / 'index.yml')
  'reloaded.'
end
