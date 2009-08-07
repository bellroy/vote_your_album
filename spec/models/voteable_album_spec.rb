require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe VoteableAlbum do
  
  describe "rating" do
    before do
      @album = VoteableAlbum.new
    end
    
    it "should return 0 by default" do
      @album.rating.should == 0
    end
    
    it "should add up the values of the assigned votes" do
      @album.stub!(:votes).and_return [Vote.new(:value => 3), Vote.new(:value => -1)]
      @album.rating.should == 2
    end
  end
  
  describe "vote" do
    before do
      @album = VoteableAlbum.new(:artist => "artist", :name => "album")
      @album.votes.stub! :create
    end
    
    it "should create an associated vote with the given value and ip" do
      @album.votes.should_receive(:create).with :value => 1, :ip => "me"
      @album.vote 1, "me"
    end
    
    it "should not allow a vote, if we have already voted" do
      @album.votes.should_receive(:create).once
      2.times { @album.vote 1, "me" }
    end
  end
  
  describe "can be voted for by?" do
    before do
      @album = VoteableAlbum.new(:artist => "artist", :name => "album")
    end
    
    it "should return true if the votes dont contain a vote by the given 'user'" do
      @album.can_be_voted_for_by?("me").should be_true
    end
    
    it "should return false if the string is in the 'voted by' list" do
      @album.stub!(:votes).and_return [Vote.new(:ip => "me")]
      @album.can_be_voted_for_by?("me").should be_false
    end
  end
  
  describe "to hash" do
    before do
      @album = VoteableAlbum.new(:artist => "artist", :name => "album")
    end
    
    it "should map all attributes into a hash" do
      @album.to_hash("me").should == { :id => nil, :artist => "artist", :name => "album", :rating => 0, :votable => true }
    end
    
    it "should have a negative votable value if this user cant vote" do
      @album.stub!(:can_be_voted_for_by?).and_return false
      @album.to_hash("me")[:votable].should be_false
    end
  end
end