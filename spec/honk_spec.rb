require File.join(File.dirname(__FILE__), 'helper')

describe Honk do
  after do
    reset_honk
  end

  describe '.root' do
    it "should return the root without arguments" do
      Honk.root.should == Honk.config[:root]
    end

    it "should set the root to the expanded path with one argument" do
      Honk.root '..'
      Honk.root.should == Pathname.new('..').expand_path
    end
  end

  describe '.paginate' do
    it "should return the pagination value without arguments" do
      Honk.paginate.should == Honk::DEFAULTS[:paginate]
    end

    it "should set the pagination with one argument" do
      Honk.paginate 20
      Honk.paginate.should == 20
    end
  end

  describe '.comment_filter' do
    it "should return the proc without arguments" do
      Honk.comment_filter.call("foo").should == "foo"
    end

    it "should change the proc with one argument" do
      Honk.comment_filter { |s| s.gsub('a', 'e') }
      Honk.comment_filter.call("mah").should == "meh"
    end

    it "should raise an error if the proc arity is wrong" do
      lambda { Honk.comment_filter {|a,b| a + b} }.should.raise ArgumentError
    end
  end

  describe '.meta' do
    it "should return the meta hash without arguments" do
      Honk.meta.should.be.kind_of(Hash)
    end

    it "should have default values" do
      Honk.meta[:author].should == "Honk default author"
      Honk.meta[:title].should  == "Honk"
      Honk.meta[:domain].should == "honk.github.com"
      Honk.meta[:email].should  == "honk@nowhere.com"
    end

    it "should change the meta hash with one argument" do
      Honk.meta({ :author => 'bar' })
      Honk.meta[:author].should == 'bar'
    end
  end

end
