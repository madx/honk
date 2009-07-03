describe Honk::Comment do

  before do
    @comment = YAML.load(mock('posts/short_sample.comments.yml').read)
  end

  describe "#initialize" do
    it "creates a new comment with default values" do
      comment = Honk::Comment.new :author => "foo", :email => "foo@bar.com",
                                  :contents => ""
      comment.should.be.kind_of Honk::Comment
      comment.timestamp.should.be.kind_of Time
      comment.spam.should.be.false
      comment.website.should.be.empty
    end
  end

  describe "#yaml_initialize" do
    it 'does the same things as #initialize when a YAML comment is read' do
      @comment.should.be.kind_of? Honk::Comment
      @comment.author.should == "Foo"
      @comment.email.should  == "foo@bar.com"
      @comment.timestamp.should.be.kind_of? Time
    end
  end

  describe "#to_yaml" do
    it "should dump the comments in the right format" do
      yaml = mock('posts/short_sample.comments.yml').read
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
