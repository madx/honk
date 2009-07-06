describe Honk::Tagging do

  before do
    @tagging = Honk::Tagging.new 'tag' => %w[post1 post2 post3]
  end

  describe '#yaml_initialize' do
    it 'returns a tagging from a tags.yml file' do
      tagging = YAML.load(mock('tags.yml').read)
      tagging.should.be.kind_of Honk::Tagging
    end
  end

  describe '#get' do
    it 'returns the post with the given tag' do
      @tagging.get('tag').should == %w[post1 post2 post3]
    end

    it 'returns an empty array if there is no tag' do
      @tagging.get('void').should.be.empty?
    end
  end

  describe '#has?' do
    it 'returns whether a tag exists or not' do
      @tagging.has?('tag').should.be.true
      @tagging.has?('void').should.be.false
    end
  end

  describe '#list' do
    it 'returns an alphabetically sorted list of tags' do
      tagging = YAML.load(mock('tags.yml').read)
      tagging.list.should == %w[bar foo]
    end
  end

  describe '#popular' do
    it 'returns a tag list sorted by usage' do
      tagging = YAML.load(mock('tags.yml').read)
      tagging.popular.should == %w[foo bar]
    end
  end

#   describe "#yaml_initialize" do
#     it "should put the contents in the @@mapping variable" do
#       Honk::Tag.class_variables.member?("@@mapping").should.be.true
#     end
#   end
# 
#   describe ".get" do
#     it "should return the post slugs associated with a tag" do
#       Honk::Tag.get("foo").should == %w[sample short_sample basic_sample]
#     end
# 
#     it "should return an empty array when a key is missing" do
#       Honk::Tag.get("missing_tag").should.be.empty
#     end
#   end
# 
#   describe ".exists?" do
#     it "should return true if this is a valid tag" do
#       Honk::Tag.exists?("foo").should.be.true
#     end
# 
#     it "should return false if this is not a valid tag" do
#       Honk::Tag.exists?("quux").should.not.be.true
#     end
#   end
# 
#   describe ".tags" do
#     it "should return a list of tags sorted alphabetically" do
#       Honk::Tag.tags.should == %w[bar foo]
#     end
#   end
# 
#   describe ".sorted_list" do
#     it "should return a list of tags sorted by most used one" do
#       Honk::Tag.sorted_list.first[0].should == 'foo'
#     end
#   end

end
