module Honk
  class App < Sinatra::Base

    configure do
      set :haml,    :attr_wrapper => '"'
      set :root,    Proc.new { Honk.options.root }
      set :views,   Proc.new { File.join(root,  'templates') }
      set :raise_errors, false
    end

    helpers Helpers

    get '/' do
      page_num = params[:page].to_i || 0
      @posts = Honk.index.page page_num
      haml :index
    end

    get '/post/:slug' do
      if Honk.index.has? params[:slug]
        @post = Post.open(params[:slug], Honk.index.map[params[:slug]])
      else raise NoPostError, params[:slug]; end

      haml :post
    end

    post '/post/:slug' do
    end

    get '/tags' do
      @tags = Honk.tags.popular

      haml :tags
    end

    get '/tags/:tag' do
      if Honk.tags.has?(params[:tag])
        @posts = Honk.tags.get(params[:tag]).collect do |post|
          Post.open(post, Honk.index.map[post])
        end
        haml :tag
      else raise NoTagError, params[:tag] end
    end

    get '/archive' do
      @posts = Honk.index.all

      haml :archive
    end

    get '/atom.xml' do
      content_type 'application/atom+xml'
      @posts = Honk.index.page 0

      builder :atom
    end

    get '/rss.xml' do
      content_type 'application/rss+xml'
      @posts = Honk.index.page 0

      builder :rss
    end

    get '/pub/*' do
      path = params[:splat].first
      raise SecurityError, path if path.include?('..')

      path = Honk.options.root / 'public' / path

      content_type MIME::Types.of(path.to_s).first.to_s
      File.read path
    end

    get '/_sync' do
      Honk.load!
      "Reloaded"
    end

    error IndexError do
      @message = MESSAGES[:no_more_posts]
      haml :error
    end

    error NoTagError do
      @message = MESSAGES[:no_tag] % env['sinatra.error'].message
      haml :error
    end

    error NoPostError do
      @message = MESSAGES[:no_post] % env['sinatra.error'].message
      haml :error
    end

    error Errno::ENOENT do
      arg = env['sinatra.error'].message
      @message = MESSAGES[:file_not_found] % arg.gsub(/^.*- /, '')

      haml :error
    end

    error SecurityError do
      @message = MESSAGES[:security] % request.env['sinatra.error'].message
      haml :error
    end

  end
end
