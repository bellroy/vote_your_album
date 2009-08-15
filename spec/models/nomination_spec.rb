require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Nomination do
  
  def clazz; Nomination end
  it_should_behave_like "it belongs to an album"
  
  describe "to hash" do
    before do
      @album = Album.new(:artist => "artist", :name => "album")
      @nomination = Nomination.new(:album => @album, :nominated_by => "ip")
    end
    
    it "should map all attributes into a hash" do
      @nomination.to_hash("me").should == { :id => nil, :artist => "artist", :name => "album", :score => 0, :voteable => true, :nominated_by => "ip" }
    end
    
    it "should have a false voteable value if this user cant vote" do
      @nomination.stub!(:can_be_voted_for_by?).and_return false
      @nomination.to_hash("me")[:voteable].should be_false
    end
  end
end