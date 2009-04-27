require File.join(File.dirname(__FILE__), 'helper')

describe Honk::Post do
  describe ".open" do
    it "should return a post" do
      Honk::Post.open('a_post', 'a_post.yml').should.be.kind_of Honk::Post
    end

    it "should assing a slug" do
      Honk::Post.open('a_post', 'a_post.yml').slug.should == 'a_post'
    end

    it "should raise an error if the file is not a post" do
      lambda {
        Honk::Post.open('foo', 'a_wrong_one.yml')
      }.should.raise Honk::FileFormatError
    end
  end

  describe "#comments" do
    it "should return an empty array if there's no comment file" do
      post = Honk::Post.open('another_post', 'another_post.yml')
      post.comments.should.be.empty
    end

    it "should return an array of comments otherwise" do
      post = Honk::Post.open('a_post', 'a_post.yml')
      post.comments.should.be.kind_of Array
    end

    it "should return an empty array if the file format is wrong" do
      post = Honk::Post.open('foo', 'wrong_comments.yml')
      post.comments.should.be.empty
    end
  end

  describe "#initialize" do
    it "should set the instance variables" do
      p = Honk::Post.new :foo => :bar
      p.instance_variables.should == ["@foo"]
    end
  end

  describe "#write" do
    before do
      @p = Honk::Post.new(
        :title => "foo", :tags => ['a', 'b'],
        :timestap => Time.now, :commentable => true,
        :contents => "<p>This is a post</p>"
      )
    end

    it "should write de dump to a file" do
      out = ""
      @p.write(out)
      out.should == YAML.dump(@p)
    end

    it "should append it if there already are posts" do
      out = ""
      @p.write(out)
      @p.write(out)
      out.should.not == YAML.dump(@p)
    end
  end

end
