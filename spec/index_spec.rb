require File.join(File.dirname(__FILE__), 'helper')

describe Index do
  before(:each) do
    YAML.load_file(Honk.root / 'index.yml')
  end

  describe "#yaml_initialize" do
    it "should expand the nil values" do
      Index.resolve("a_post").should eql("a_post.yml")
    end

    it "should raise an error if the file format is wrong" do
      lambda {
        YAML.load("--- !honk.yapok.org,2009/Index\n- foo")
      }.should raise_error(FileFormatError)
    end
  end

  describe ".has?" do
    it "should return true if there is a matching key in the entries" do
      Index.has?("a_post").should be_true
    end

    it "should return false otherwise" do
      Index.has?("a_boring_post").should be_false
    end
  end

  describe ".fetch" do
    it "should return an array of posts" do
      Index.fetch(0..1).should be_an(Array)
      Index.fetch(0..1)[0].should be_a(Honk::Post)
    end

    it "should raise an error if the first index is out of range" do
      lambda { Index.fetch(10..11) }.should raise_error(Honk::OutOfRangeError)
    end
  end

  describe "pagination" do
    before do
      index = []
      0.upto(99) {|i| index << {"post#{i}", "post#{i}.yml"} }
      YAML.load YAML.dump(index).gsub('---', '--- !honk.yapok.org,2009/Index')
    end

    describe ".pages" do
      it "should return the number of pages when called with no argument" do
        Index.pages.should eql(10)  
      end

      it "should return the page for a post when called with a slug" do
        Index.pages("post0").should eql(0)
        Index.pages("post55").should eql(5)
      end
    end
  end


end
