require File.join(File.dirname(__FILE__), 'helper')

describe Tag do
  before(:each) do
    YAML.load_file(Honk.root / 'tags.yml')
  end

  describe "#yaml_initialize" do
    it "should raise an error if the file format is wrong" do
      lambda {
        YAML.load("--- !honk.yapok.org,2009/Tags\n- foo")
      }.should raise_error(FileFormatError)
    end

    it "should put the contents in the @@mapping variable" do
      Tag.class_variables.member?("@@mapping").should be_true
    end
  end

  describe ".get" do
    it "should return the post slugs associated with a tag" do
      Tag.get("foo").should eql(%w[a_post])
    end

    it "should return an empty array when a key is missing" do
      Tag.get("missing_tag").should be_empty
    end
  end

  describe ".exists?" do
    it "should return true if this is a valid tag" do
      Tag.exists?("foo").should be_true
    end

    it "should return false if this is not a valid tag" do
      Tag.exists?("quux").should_not be_true
    end
  end

  describe ".tags" do
    it "should return a list of tags sorted alphabetically" do
      Tag.tags.should eql(%w[bar foo overused])
    end
  end

  describe ".sorted_list" do
    it "should return a list of tags sorted by most used one" do
      Tag.sorted_list.first[0].should eql('overused')
    end
  end
end
