%w[rubygems sinatra pathname].each do |lib|
  require lib
end
require File.join(File.dirname(__FILE__), 'lib', 'honk') 
include Honk

# configuration
Honk.setup do
end

configure do
  set :haml, :attr_wrapper => '"'
end

YAML.load_file(Honk.root / 'index.yml')

helpers do
  def partial(name, opts={})
    haml name, opts.merge(:layout => false)
  end

  def tag_link(t)
    partial "%a{:href => '/tag/#{t}', :title => 'View posts tagged #{t}'} #{t}"
  end

  def comments_link(post)
    comment_string = "#{post.comments.length} comment"
    comment_string << 's' if post.comments.length != 1
    partial %Q{
      %%a{:href => '/post/%s', :title => 'View comments for this post'} %s
    }.gsub("\n", '').strip % [post.slug, comment_string]
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

get '/feed' do
end

get '/_reload' do
  YAML.load_file(Honk.root / 'index.yml')
  "reloaded."
end
