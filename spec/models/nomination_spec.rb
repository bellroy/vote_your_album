require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Nomination do
  
  describe "album accessors" do
    before do
      @album = Album.new(:artist => "artist", :name => "album")
      @nomination = Nomination.new(:album => @album)
    end
    
    it "should return the artist of the album" do
      @nomination.artist.should == "artist"
    end
    
    it "should return the album name of the album" do
      @nomination.name.should == "album"
    end
  end
  
  describe "owned by?" do
    before do
      @nomination = Nomination.new(:nominated_by => "me")
    end
    
    it "should return true if we have nominated the album" do
      @nomination.should be_owned_by("me")
    end
    
    it "should return false if haven't nominated the album" do
      @nomination.should_not be_owned_by("you")
    end
  end
  
  describe "vote" do
    before do
      @nomination = Nomination.new(:score => 0)
      @nomination.votes.stub!(:create).and_return true
      @nomination.stub! :save
    end
    
    it "should create an associated vote with the given value and ip" do
      @nomination.votes.should_receive(:create).with :value => 1, :ip => "me"
      @nomination.vote 1, "me"
    end
    
    it "should update the score attribute" do
      @nomination.should_receive(:score=).with 2
      @nomination.vote 2, "me"
    end
    
    it "should save the nomination after we have created a vote" do
      @nomination.should_receive :save
      @nomination.vote 2, "me"
    end
    
    it "should not allow a vote, if we have already voted" do
      @nomination.votes.should_receive(:create).once
      2.times { @nomination.vote 1, "me" }
    end
    
    describe "eliminate" do
      before do
        @nomination.stub! :update_attributes
      end
      
      it "should not change the status to 'deleted' swhen the threshold isnt reached" do
        @nomination.should_not_receive(:status=).with "deleted"
        @nomination.stub!(:score).and_return -2
        @nomination.vote -2, "me"
      end

      it "should change the status to 'deleted' when we have reached the elimination threshold (ELIMINATION_SCORE)" do
        @nomination.should_receive(:status=).with "deleted"
        @nomination.stub!(:score).and_return -3
        @nomination.vote -3, "me"
      end
    end
  end
  
  describe "can be voted for by?" do
    before do
      @nomination = Nomination.new
    end
    
    it "should return true if the votes dont contain a vote by the given 'user'" do
      @nomination.can_be_voted_for_by?("me").should be_true
    end
    
    it "should return false if the string is in the 'voted by' list" do
      @nomination.stub!(:votes).and_return [Vote.new(:ip => "me")]
      @nomination.can_be_voted_for_by?("me").should be_false
    end
  end
  
  describe "remove" do
    before do
      @nomination = Nomination.new(:nominated_by => "me")
      @nomination.stub! :update_attributes
    end
    
    it "should do nothing if we havent nominated the album" do
      @nomination.should_not_receive :update_attributes
      @nomination.remove "other"
    end
    
    it "should set the status to 'deleted' when we are the 'owner'" do
      @nomination.should_receive(:update_attributes).with :status => "deleted"
      @nomination.remove "me"
    end
  end
end