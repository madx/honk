describe Honk do

  after do
    reset_honk
  end

  describe 'configuration accessors/setters' do
    it "has root()" do
      Honk.root.should == Honk.config[:root]
      Honk.root '..'
      Honk.root.should == Pathname.new('..').expand_path
      lambda { Honk.root "/foo/bar/baz" }.should.raise
    end

    it "has paginate()" do
      Honk.paginate.should == Honk::DEFAULTS[:paginate]
      Honk.paginate 20
      Honk.paginate.should == 20
    end

    it "has comment_filter()" do
      Honk.comment_filter.call("foo").should == "foo"
      Honk.comment_filter { |s| s.gsub('a', 'e') }
      Honk.comment_filter.call("mah").should == "meh"
      lambda { Honk.comment_filter {|a,b| a + b} }.should.raise
    end

    it "has post_comment_hook()" do
      Honk.post_comment_hook.should.be.kind_of Proc
      Honk.post_comment_hook { |p,c| "foo" }
      Honk.post_comment_hook.call(nil,nil).should == "foo"
      lambda { Honk.post_comment_hook {|a| } }.should.raise
    end

    it "has meta()" do
      Honk.meta.should.be.kind_of(Hash)
      Honk.meta[:author].should == "Honk default author"
      Honk.meta[:title].should  == "Honk"
      Honk.meta[:domain].should == "honk.github.com"
      Honk.meta[:email].should  == "honk@nowhere.com"
      Honk.meta({ :author => 'bar' })
      Honk.meta[:author].should == 'bar'
    end
  end

end
