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
      if Honk.index.has? params[:slug]
        redirect '/' unless params[:c_nickname].strip.empty? # antispam

        @errors = []
        @errors << :c_author   if params[:c_author].strip.empty?
        @errors << :c_email    if params[:c_email].strip.empty?
        if params[:c_contents].empty? || params[:c_contents] =~ /\A\s+\Z/
          @errors << :c_contents
        end

        unless @errors.empty?
          begin
            @post = Post.open(params[:slug], Honk.index.map[params[:slug]])
          rescue Errno::ENOENT
            raise IndexError, params[:slug]
          end

          haml :post
        else
          post = Post.open(params[:slug], Honk.index.map[params[:slug]])
          args = {
            :author    => params[:c_author],
            :email     => params[:c_email],
            :website   => params[:c_website],
            :contents  => Honk.options.comment_filter.call(
              params[:c_contents].gsub("\r\n", "\n")
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
            comment_file = Honk.index.map[params[:slug]].
              gsub(/\.yml$/, '.comments.yml')
          rescue
            raise IndexError, params[:slug]
          end

          comment_file = Honk.options.root / 'posts' / comment_file
          comment = Comment.new args
          File.open(comment_file, 'a') {|f| comment.write(f) }

          Honk.options.comment_hook.call(post, comment)

          redirect request.env['REQUEST_URI']+"#comments"
        end
      else raise NoPostError, params[:slug]; end
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
