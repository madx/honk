%w[rubygems sinatra pathname].each do |lib|
  require lib
end
class Pathname; alias / join; end
require Pathname.new(__FILE__).dirname / 'lib' / 'honk'
include Honk

# configuration
Honk.setup do
end

helpers do
  def partial(name, opts)
    haml name, opts.merge(:layout => false)
  end
end

get '/' do
end

get '/post/:name' do
end

get '/feed' do
end

get '/tag/:tag' do
end
