require 'rack/test'
require 'hpricot'
require Honk::PATH / 'honk' / 'app'

Honk::App.set :environment, :test

Honk.load!

def message(sym)
  Honk::Helpers::MESSAGES[sym]
end

def html()
  Hpricot(@browser.last_response.body)
end

def response_ok
  @browser.last_response.should.be.ok
end

def server_error
  @browser.last_response.should.not.be.ok
  @browser.last_response.status.should == 500
end

describe Honk::App do

  before do
    @browser = Rack::Test::Session.new(Honk::App)
  end

  it 'sets sinatra options' do
    Honk::App.haml[:attr_wrapper].should == '"'
    Honk::App.root.should == Honk.options.root
    Honk::App.views.should == File.join(Honk.options.root, 'templates')
    Honk::App.raise_errors.should.be.false
  end

  it 'has helpers' do
    Honk::App::TEMPLATES.should.be.kind_of Hash
    Honk::App::MESSAGES.should.be.kind_of Hash
    Honk::App.new.should.respond_to :partial
  end

  describe 'get /' do
    it 'returns the index page' do
      @browser.get '/'
      response_ok
      (html/"#contents .post-contents").size.should == Honk.options.paginate
      (html/".pagination a").size.should == Honk.index.list.length
    end

    it 'can be given a page number' do
      @browser.get '/', :page => 1
      response_ok
      (html/"h2 a").text.should == "Another post"
    end

    it 'shows the error page is the given page is out of range' do
      @browser.get '/', :page => 1000
      server_error
      (html/"#contents").text.
        should.include message(:no_more_posts)
    end
  end

  describe 'get /post/:name' do
    it 'returns the page for a post' do
      @browser.get '/post/sample'
      response_ok
      @browser.last_response.body.should.
        include Honk::Post.open('', Honk.index.map['sample']).contents
    end

    it 'raises an error if there is no such post' do
      @browser.get '/post/void'
      server_error
      @browser.last_response.body.
        should.include message(:no_post) % 'void'
    end
  end

  describe 'post /post/:name' do
  end

  describe 'get /tags' do
    it 'serves the page tag' do
      @browser.get '/tags'
      response_ok

      Honk.tags.list.each do |tag|
        @browser.last_response.body.should.include tag
      end
    end
  end

  describe 'get /tags/:name' do
    it 'show posts for a given tag' do
      @browser.get '/tags/foo'
      response_ok

      posts = Honk.tags.get('foo').collect do |post|
        Honk::Post.open(post, Honk.index.map[post])
      end

      posts.each do |post|
        @browser.last_response.body.should.include post.title
      end
    end

    it 'raises an error if the tag is unknown' do
      @browser.get '/tags/void'
      server_error

      @browser.last_response.body.
        should.include message(:no_tag) % 'void'
    end
  end

  describe 'get /archive' do
    it 'return the full post archive' do
      @browser.get '/archive'
      response_ok

      Honk.index.all.each do |post|
        @browser.last_response.body.should.include post.title
        @browser.last_response.body.should.include post.formatted_timestamp
      end
    end
  end

  describe 'get /atom.xml' do
    it 'should serve the Atom feed' do
      @browser.get '/atom.xml'
      response_ok

      @browser.last_response.headers['Content-Type'].
        should == 'application/atom+xml'
    end
  end

  describe 'get /rss.xml' do
    it 'should serve the RSS feed' do
      @browser.get '/rss.xml'
      response_ok

      @browser.last_response.headers['Content-Type'].
        should == 'application/rss+xml'
    end
  end

  describe 'get /pub/*' do
    it 'should serve a file from the public folder' do
      @browser.get '/pub/master.css'
      response_ok

      @browser.last_response.body.should == mock('public/master.css').read
      @browser.last_response.headers['Content-Type'].
        should == 'text/css'
    end

    it 'should raise a SecurityError if the path contains ..' do
      @browser.get '/pub/../'
      server_error

      @browser.last_response.body.should.
        include message(:security) % '../'
    end
  end

  describe 'get /_sync' do
    it 'reloads the index and tags file' do
      iid, tid = Honk.index.object_id, Honk.tags.object_id

      @browser.get '/_sync'
      response_ok

      iid.should.not.be == Honk.index.object_id
      tid.should.not.be == Honk.tags.object_id

      @browser.last_response.body.should == "Reloaded"
    end
  end

end
