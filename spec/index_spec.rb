require File.join(File.dirname(__FILE__), 'helper')

describe Honk::Index do
  before do
    YAML.load_file(Honk.root / 'index.yml')
  end

  describe "#yaml_initialize" do
    it "should expand the nil values" do
      Honk::Index.resolve("a_post").should == "a_post.yml"
    end

    it "should expand tildes" do
      Honk::Index.resolve("a_last_one").should == "01_a_last_one.yml"
    end

    it "should raise an error if the file format is wrong" do
      lambda {
        YAML.load("--- !honk.yapok.org,2009/Index\n- foo")
      }.should.raise Honk::FileFormatError
    end
  end

  describe ".has?" do
    it "should return true if there is a matching key in the entries" do
      Honk::Index.has?("a_post").should.be.true
    end

    it "should return false otherwise" do
      Honk::Index.has?("a_boring_post").should.be.false
    end
  end

  describe ".fetch" do
    it "should return an array of posts" do
      Honk::Index.fetch(0..1).should.be.kind_of    Array
      Honk::Index.fetch(0..1)[0].should.be.kind_of Honk::Post
    end

    it "should raise an error if the first index is out of range" do
      lambda { Honk::Index.fetch(10..11) }.should.raise Honk::OutOfRangeError
    end
  end

  describe ".all" do
    it "should return all the posts" do
      Honk::Index.all.should.be.kind_of Array
      Honk::Index.all.length.should == Honk::Index.list.length
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
        Honk::Index.pages.should == 10
      end

      it "should return the page for a post when called with a slug" do
        Honk::Index.pages("post0").should == 0
        Honk::Index.pages("post55").should == 5
      end
    end
  end


end
