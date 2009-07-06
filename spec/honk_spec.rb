describe 'Honk' do
  before do
    reset_honk
    @defaults = Metash.new
    @defaults.instance_eval &Honk::DEFAULTS
  end

  it 'has @@index end @@tags' do
    Honk.load!

    Honk.index.should.be.kind_of Honk::Index
    Honk.tags.should.be.kind_of  Honk::Tagging
  end

  describe 'Options' do
    should 'be accessible with the .options method' do
      Honk.options.should.be.kind_of Metash
    end

    should 'have default values' do
      Honk.options.should == @defaults
    end
  end

  describe 'Setup' do
    it 'should change the options' do
      Honk.setup { paginate 20 }
      Honk.options.paginate.should == 20
    end

    it 'should not remove previously set options' do
      Honk.setup { paginate 20 }
      Honk.options.meta.should == @defaults.meta
    end
  end

  describe 'Configuration check' do
    it 'fails if there are unset mandatory options' do
      Honk::DEFAULT_OPTIONS.each do |opt|
        Honk.options.__send__(opt, nil)
      end
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages].each do |k,v|
          v.should == "#{k} is missing"
        end
      end
    end

    should 'not fail with the default options' do
      Honk.check_options[:valid].should.be.true
    end

    it 'checks that paginate is a Numeric' do
      [10, 10.0, Infinity].each do |value|
        Honk.options.paginate value
        Honk.check_options[:valid].should.be.true
      end

      Honk.options.paginate :foo
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages][:paginate].should == 'wrong value for paginate'
      end
    end

    it 'checks that root is a pathname' do
      Honk.options.root '/etc/passwd'
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages][:root].should == '"/etc/passwd" is not a Pathname'
      end
    end

    it 'checks that root is a folder' do
      Honk.options.root Pathname.new('/etc/passwd')
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages][:root].should == '/etc/passwd is not a folder'
      end
    end

    it 'checks that the root folder is writable' do
      Honk.options.root Pathname.new('/proc')
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages][:root].should == '/proc is not writable'
      end
    end

    it 'checks that the comment_filter is a proc' do
      Honk.options.comment_filter :foo
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages][:comment_filter].
          should == 'comment_filter must be a proc'
      end
    end

    it 'checks that the comment_filter has the right arity' do
      Honk.options.comment_filter lambda {}
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages][:comment_filter].
          should == 'comment_filter takes one argument'
      end
    end

    it 'checks that the comment_hook is a proc' do
      Honk.options.comment_hook :foo
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages][:comment_hook].
          should == 'comment_hook must be a proc'
      end
    end

    it 'checks that the comment_hook has the right arity' do
      Honk.options.comment_hook lambda {}
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages][:comment_hook].
          should == 'comment_hook takes two arguments'
      end
    end

    it 'checks that the metadata is a hash' do
      Honk.options.meta :foo
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages][:meta].
          should == 'meta must be an hash'
      end
    end

    it 'checks that required metada is there' do
      Honk.options.meta _= {}
      Honk.check_options.tap do |check|
        check[:valid].should.be.false
        check[:messages][:meta].
          should == 'missing metadata: author, title, domain, email and description'
      end
    end
  end
end
