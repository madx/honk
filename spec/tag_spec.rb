describe Honk::Tag do
  before do
    YAML.load_file(Honk.root / 'tags.yml')
  end

  describe "#yaml_initialize" do
    it "should raise an error if the file format is wrong" do
      lambda {
        YAML.load("--- !honk.yapok.org,2009/Tags\n- foo")
      }.should.raise Honk::FileFormatError
    end

    it "should put the contents in the @@mapping variable" do
      Honk::Tag.class_variables.member?("@@mapping").should.be.true
    end
  end

  describe ".get" do
    it "should return the post slugs associated with a tag" do
      Honk::Tag.get("foo").should == %w[a_post]
    end

    it "should return an empty array when a key is missing" do
      Honk::Tag.get("missing_tag").should.be.empty
    end
  end

  describe ".exists?" do
    it "should return true if this is a valid tag" do
      Honk::Tag.exists?("foo").should.be.true
    end

    it "should return false if this is not a valid tag" do
      Honk::Tag.exists?("quux").should.not.be.true
    end
  end

  describe ".tags" do
    it "should return a list of tags sorted alphabetically" do
      Honk::Tag.tags.should == %w[bar foo overused]
    end
  end

  describe ".sorted_list" do
    it "should return a list of tags sorted by most used one" do
      Honk::Tag.sorted_list.first[0].should == 'overused'
    end
  end
end
