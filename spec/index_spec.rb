describe Honk::Index do
  before do
    @index = YAML.load(mock('index.yml').read)
  end

  describe "#initialize()" do
    it 'has readable list and map attribudes' do
      [:list, :map].each do |meth|
        @index.should.respond_to     meth
        @index.should.not.respond_to "#{meth}="
      end
    end

    it 'takes an hash to build an index' do
      index = Honk::Index.new [
        { 'sample'       => '01_~.yml' },
        { 'basic_sample' => nil        },
        { 'short_sample' => '~.yml'    }
      ]
      index.should.be.kind_of? Honk::Index
      index.list.should == %w[sample basic_sample short_sample]
      index.map.should  == {
        'sample'       => '01_sample.yml',
        'basic_sample' => 'basic_sample.yml',
        'short_sample' => 'short_sample.yml'
      }
    end
  end

  describe "#yaml_initialize()" do
    it 'should behave like #initialize when reading from a YAML file' do
      @index.should.be.kind_of Honk::Index
      @index.list.should == %w[sample basic_sample short_sample]
      @index.map.should  == {
        'sample'       => '01_sample.yml',
        'basic_sample' => 'basic_sample.yml',
        'short_sample' => 'short_sample.yml'
      }
    end
  end

  describe ".has?" do
    it "should return true if there is a matching key in the entries" do
      @index.has?("sample").should.be.true
    end

    it "should return false otherwise" do
      @index.has?("void").should.be.false
    end
  end

  describe ".fetch" do
    it "should return an array of posts" do
      @index.fetch(0..1).should.be.kind_of    Array
      @index.fetch(0..1)[0].should.be.kind_of Honk::Post
    end

    it "should raise an error if the first index is out of range" do
      lambda { @index.fetch(10..11) }.should.
        raise Honk::IndexError, "first item is out of range"
    end
  end

  describe ".all" do
    it "should return all the posts" do
      @index.all.should.be.kind_of Array
      @index.all.length.should == @index.list.length
    end
  end

  describe "pagination" do
    before do
      @items = []
      0.upto(99) {|i| @items << {"post#{i}", "post#{i}.yml"} }
      @index = Honk::Index.new(@items)
      class << @index
        def fetch(range)
          raise OutOfRangeError if range.first >= @list.length
          @list[range].collect do |slug|
            {slug => map[slug]}
          end
        end
      end
    end

    describe ".pages()" do
      it "should return the number of pages" do
        @index.pages.should == 100
      end
    end

    describe '.page()' do
      it 'should return all the posts for a given page' do
        page = @index.page(0)
        page.first.should == {'post0' => 'post0.yml'}
        page.last.should  == {'post0' => 'post0.yml'}
      end

      it 'should return all posts for page(0) when paginate is infinity' do
        Honk.options.paginate Infinity
        @index.page(0).should == @items
      end
    end
  end

  describe '.dump()' do
    it 'should make a YAML dump of the post' do
      @index.dump.should == YAML.load(mock('index.yml').read).dump
      @index.dump.should == Honk::Index.new([
        { 'sample'       => '01_~.yml' },
        { 'basic_sample' => nil        },
        { 'short_sample' => '~.yml'    }
      ]).dump
    end
  end

  describe '.push()' do
    it 'pushes an item to the index, performing expansion' do
      @index.push('foo1', 'bar')
      @index.push('foo2')
      @index.push('foo3', '01.foo')

      %w[foo1 foo2 foo3].each do |slug|
        @index.list.should.include slug
      end
    end

    it 'raise an IndexError if the slug is already in the index' do
      lambda { @index.push('sample') }.should.
        raise Honk::IndexError, "sample is already in the index"
    end
  end

end
