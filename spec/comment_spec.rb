describe Honk::Comment do

  describe "#initialize" do
    it "should set the instance variables" do
      c = Honk::Comment.new :foo => :bar
      c.instance_variables.should == ["@foo"]
    end
  end

  describe "#yaml_initialize" do
    it "should raise an error if the file is not a comment" do
      lambda {
        YAML.load("--- !honk.yapok.org,2009/Comment\n- fail")
      }.should.raise Honk::FileFormatError
    end
  end

  describe "#to_yaml" do
    it "should dump the comments in the right format" do
      yaml = File.read(Honk.root/'posts'/'yaml_dump_test.comments.yml')
      c = YAML.load(yaml)
      YAML.dump(c).should == yaml
    end
  end

  describe "#write" do
    before do
      @c = Honk::Comment.new(
        :author  => "foo",     :email => "bar@baz.com",
        :website => "baz.com", :timestamp => Time.now, :contents => "foo")
    end

    it "should write the dump to a file" do
      out = ""
      @c.write(out)
      out.should == YAML.dump(@c)
    end

    it "should append it if there already are comments" do
      out = ""
      @c.write(out)
      @c.write(out)
      out.should.not == YAML.dump(@c)
    end
  end

end
