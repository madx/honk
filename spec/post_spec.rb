require File.join(File.dirname(__FILE__), 'helper')

describe Post do
  describe ".open" do
    it "should return a post" do
      Post.open('a_post', 'a_post.yml')
    end

    it "should assing a slug" do
      Post.open('a_post', 'a_post.yml').slug.should eql('a_post')
    end

    it "should raise an error if the file is not a post" do
      lambda { Post.open('foo', 'a_wrong_one.yml') }.should 
        raise_error FileFormatError
    end
  end

  describe "#comments" do
    it "should return an empty array if there's no comment file" do
      post = Post.open('another_post', 'another_post.yml')
      post.comments.should be_empty
    end

    it "should return an array of comments otherwise" do
      post = Post.open('a_post', 'a_post.yml')  
      post.comments.should be_an(Array)
    end

    it "should return an empty array if the file format is wrong" do
      post = Post.open('foo', 'wrong_comments.yml')
      post.comments.should be_empty
    end
  end
end
