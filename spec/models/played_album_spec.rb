require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe PlayedAlbum do
  
  def clazz; PlayedAlbum end
  it_should_behave_like "it belongs to an album"
  
  describe "remaining" do
    it "should use the result of NECESSARY_VOTES - rating" do
      @p_album = PlayedAlbum.new
      @p_album.stub!(:rating).and_return 2
      @p_album.remaining.should == 1
    end
  end
  
  describe "to hash" do
    before do
      @album = Album.new(:artist => "artist", :name => "album")
      @p_album = PlayedAlbum.new(:album => @album)
    end
    
    it "should map all attributes into a hash" do
      @p_album.to_hash("me").should == { :artist => "artist", :name => "album", :remaining => 3, :votable => true }
    end
    
    it "should have a false votable value if this user cant vote" do
      @p_album.stub!(:can_be_voted_for_by?).and_return false
      @p_album.to_hash("me")[:votable].should be_false
    end
  end
end