require 'stringio'

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

      post = YAML.load(mock('posts/short_sample.yml').read)
      post.tags.        should.be.kind_of Array
      post.commentable. should.be.true
      post.tags.        should.be.empty

      lambda {
        YAML.load mock('posts/wrong_sample_1.yml').read
      }.should.raise ArgumentError, 'contents are missing'

      lambda {
        YAML.load mock('posts/wrong_sample_2.yml').read
      }.should.raise ArgumentError, 'title is missing'
    end
  end

  describe '.open()' do
    it "opens a post given it's slug and path" do
      post = Honk::Post.open('sample', 'basic_sample.yml')

      post.slug.should == 'sample'
      post.file.should == 'basic_sample.yml'
    end

    it "sets the timestamp to the file's mtime if it's missing" do
      post = Honk::Post.open('sample', 'short_sample.yml')

      post.timestamp.should == mock('posts/short_sample.yml').mtime
    end

    it 'should raise an ArgumentError if the post is invalid' do
      lambda {
        Honk::Post.open('sample', 'wrong_sample_1.yml')
      }.should.raise ArgumentError
    end
  end

  describe '#to_yaml' do
    before do
      @post  = Honk::Post.open('sample', 'basic_sample.yml')
      @short = Honk::Post.open('sample', 'short_sample.yml')
    end

    it 'should dump with the right tag' do
      dump = YAML.dump(@post)
      dump.should.include '--- !honk.yapok.org,2009/Post'
    end

    it 'should use the right order' do
      lines = YAML.dump(@post).split($/).select {|l| l =~ /^:\w+/}
      lines.map! {|l| l.gsub(/^:(\w+):.+$/, '@\1') }
      lines.should == @post.to_yaml_properties
    end
  end

  describe '#comments' do
    before do
      @with    = Honk::Post.open('sample', 'short_sample.yml')
      @without = Honk::Post.open('sample', 'basic_sample.yml')
    end

    it 'returns the comments as an array' do
      @with.comments.should.be.kind_of    Array
      @without.comments.should.be.kind_of Array
    end

    it 'returns an empty array when there are no comments' do
      @without.comments.should.be.empty
    end

    # it 'uses lazy-loading to avoid reloading comments'
  end

  describe '#write' do
    before do
      @post = Honk::Post.open('sample', 'basic_sample.yml')
    end

    it 'should write the dump to the given fileish' do
      buffer = StringIO.new
      @post.write buffer
      buffer.string.should == YAML.dump(@post)
    end
  end

  describe 'formatted_timestamp' do
    it 'returns the timestamp formatted with Honk.options.time_format' do
      @post = Honk::Post.open('sample', 'basic_sample.yml')
      @post.formatted_timestamp.
        should == @post.timestamp.strftime(Honk.options.time_format)
    end
  end
end
