module Honk
  module Helpers

    TEMPLATES = {
      :stylesheet => '%%link{%s}',
      :link       => '%%a{%s} %s',
      :tag_link   =>
        '%%a{:href => "/tags/%s", :title => "View posts tagged %s"} %s',
      :post_link  => '%%a{:href => "/post/%s", :title => "View this post"} %s',
      :label      => '%%label{:for => "%s"} %s:',
      :input      => '%%input{%s}',
      :textarea   => '%%textarea{%s} %s',
      :req_field  => '%%span.error This field is required'
    }

    MESSAGES = {
      :no_more_posts  => "There are no more posts!",
      :no_post        => "No such post <kbd>%s</kbd>",
      :no_tag         => "No such tag <kbd>%s</kbd>",
      :file_not_found => "A file is missing: %s",
      :security       => "Invalid path: %s"
    }

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

    def stylesheet
      args = {
        :rel => "stylesheet", :type => "text/css",
        :media => "screen", :href => versioned_css
      }
      template :stylesheet, args.inspect
    end

    def versioned_css
      mtime = File.mtime(File.join(options.root, 'public', 'master.css')).to_i
      "/pub/master.css?%s" % mtime
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
      email = Honk.options.meta[:email].gsub('@', '[REMOVETHIS]@')
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
      contents = (params[name.to_sym] || '').gsub("\r\n", '&#10;')
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


    def field_required(member)
      member ? template(:req_field) : ''
    end

    def tag_url(t)
      "http://" + File.join(Honk.options.meta[:domain], 'tags', t)
    end

    def post_url(p)
      "http://" + File.join(Honk.options.meta[:domain], 'post', p.slug)
    end

    def blog_url
      "http://" + Honk.options.meta[:domain] + '/'
    end

    def tag_item_count(items)
      len = items.length
      len == 1 ? "#{len} item" : "#{len} items"
    end

  end
end
