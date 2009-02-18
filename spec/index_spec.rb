require File.join(File.dirname(__FILE__), 'helper')

describe Index do
  before(:each) do
    YAML.load_file(Honk.root / 'index.yml')
  end

  describe ".yaml_initialize" do
    it "should expand the nil values" do
      Index.resolve("a_post").should eql("a_post.yml")
    end

    it "should raise an error if the content of the yaml file is not a hash" do
      lambda {
        YAML.load("--- !honk.yapok.org,2009/Index\n- foo")
      }.should raise_error(Honk::IndexError)
    end
  end

  describe ".has?" do
    it "should return true if there is a matching key in the entries" do
      Index.has?("a_post").should be_true
    end

    it "should return false else" do
      Index.has?("a_boring_post").should be_false
    end
  end

  describe ".fetch" do
    it "should return an array of posts" do
      Index.fetch(0..1).should be_an(Array)
      Index.fetch(0..1)[0].should be_a(Honk::Post)
    end

    it "should raise an error if the indexes are out of range" do
      lambda { Index.fetch(10..11) }.should raise_error(Honk::OutOfRangeError)
      lambda { Index.fetch(0..100) }.should raise_error(Honk::OutOfRangeError)
    end
  end
end
