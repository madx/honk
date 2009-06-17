describe Honk::Post do

  describe '#initialize()' do
    before do
      @post = Honk::Post.new :title => 'foo', :contents => 'bar'
    end

    it 'raises an ArgumentError when contents are missing' do
      lambda {
        Honk::Post.new :contents => ''
      }.should.raise ArgumentError, "contents are missing"
    end

    it 'raises an ArgumentError when title is missing' do
      lambda {
        Honk::Post.new :title => 'foo'
      }.should.raise ArgumentError, "title is missing"
    end

    it 'sets a default timestamp' do
      @post.timestamp.should.be.kind_of Time
    end

    it 'sets commentable to false' do
      @post.commentable.should.be.true
    end

    it 'sets an empty tag array' do
      @post.tags.should.be.kind_of Array
      @post.tags.should.be.empty
    end
  end

  describe '#yaml_initialize()' do
    it 'does the same thing as #initialize when a YAML post is read' do
      sample = mock('posts/basic_sample.yml')
      YAML.load(sample.read).should.be.kind_of Honk::Post

      sample = mock('posts/short_sample.yml')
      post = YAML.load(sample.read)
      post.tags.        should.be.kind_of Array
      post.commentable. should.be.true
      post.tags.        should.be.empty

      lambda {
        sample = mock('posts/wrong_sample_1.yml')
        YAML.load(sample.read)
      }.should.raise ArgumentError, 'contents are missing'

      lambda {
        sample = mock('posts/wrong_sample_2.yml')
        YAML.load(sample.read)
      }.should.raise ArgumentError, 'title is missing'
    end
  end

  describe '.open()' do
    it "opens a post given it's slug and path" do
      post = Honk::Post.open('sample', 'basic_sample')

      post.slug.should == 'sample'
      post.file.should == 'basic_sample'
    end

    it "sets the timestamp to the file's mtime if it's missing" do
      post = Honk::Post.open('sample', 'short_sample')

      post.timestamp.should == mock('posts/short_sample.yml').mtime
    end

    it 'should raise an ArgumentError if the post is invalid' do
      lambda {
        Honk::Post.open('sample', 'wrong_sample_1')
      }.should.raise ArgumentError
    end
  end

  describe '#comments' do
  end

  describe '#to_yaml' do
  end

  describe '#write' do
  end

  # describe "#comments" do
  #   it "should return an empty array if there's no comment file" do
  #     post = Honk::Post.open('another_post', 'another_post.yml')
  #     post.comments.should.be.empty
  #   end

  #   it "should return an array of comments otherwise" do
  #     post = Honk::Post.open('a_post', 'a_post.yml')
  #     post.comments.should.be.kind_of Array
  #   end

  #   it "should return an empty array if the file format is wrong" do
  #     post = Honk::Post.open('foo', 'wrong_comments.yml')
  #     post.comments.should.be.empty
  #   end
  # end

  # describe "#initialize" do
  #   it "should set the instance variables" do
  #     p = Honk::Post.new
  #     p.instance_variables.sort.should == %w[@title @timestamp @contents @commentable @tags].sort
  #   end
  # end

  # describe "#write" do
  #   before do
  #     @p = Honk::Post.new(
  #       :title => "foo", :tags => ['a', 'b'],
  #       :timestamp => Time.now, :commentable => true,
  #       :contents => "<p>This is a post</p>"
  #     )
  #   end

  #   it "should write the dump to a file" do
  #     out = ""
  #     @p.write(out)
  #     out.should == YAML.dump(@p)
  #   end

  #   it "should append it if there's already a post" do
  #     out = ""
  #     @p.write(out)
  #     @p.write(out)
  #     out.should.not == YAML.dump(@p)
  #   end
  # end

end
