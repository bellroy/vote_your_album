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
  
  describe "add" do
    before do
      @album = Album.new
      @nomination = Nomination.new(:album => @album)
      @nomination.songs.stub! :<<
      @nomination.stub! :save
      
      @album.songs.stub!(:get).and_return @song = Song.new
    end
    
    it "should try to find the song in the album's songs" do
      @album.songs.should_receive(:get).with 123
      @nomination.add 123
    end
    
    it "should add the song to the nominations songs" do
      @nomination.songs.should_receive(:<<).with @song
      @nomination.add 123
    end
    
    it "should save the nomination in the end" do
      @nomination.should_receive :save
      @nomination.add 123
    end
    
    it "should not add the song if we cant find it" do
      @album.songs.stub!(:get).and_return nil
      @nomination.songs.should_not_receive :<<
      @nomination.add 123
    end
    
    it "should not add the album if it's already in the nomination's song list" do
      @nomination.stub!(:songs).and_return [@song]
      @nomination.songs.should_not_receive :<<
      @nomination.add 123
    end
  end
  
  describe "delete" do
    before do
      @nomination = Nomination.new(:id => 2)
      
      NominationSong.stub!(:first).and_return @join = NominationSong.new
      @join.stub! :destroy
    end
    
    it "should try to find the associated song" do
      NominationSong.stub!(:first).with(:nomination_id => 2, :song_id => 123).and_return @join
      @nomination.delete 123
    end
    
    it "should remove the song from the nomination's songs" do
      @join.should_receive :destroy
      @nomination.delete 123
    end
    
    it "should not remove the song if we cant find it" do
      NominationSong.stub!(:first).and_return nil
      @join.should_not_receive :destroy
      @nomination.delete 123
    end
  end
  
  describe "vote" do
    before do
      @nomination = Nomination.new(:score => 0)
      @nomination.votes.stub!(:create).and_return true
      @nomination.negative_votes.stub!(:create).and_return true
      @nomination.stub! :save
    end
    
    it "should create an associated vote with the given value and ip" do
      @nomination.votes.should_receive(:create).with :value => 1, :ip => "me", :type => "vote"
      @nomination.vote 1, "me"
    end
    
    it "should create an associated negative vote with the given (negative) value and ip" do
      @nomination.negative_votes.should_receive(:create).with :value => -1, :ip => "me", :type => "vote"
      @nomination.vote -1, "me"
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

      it "should change the status to 'deleted' when we have reached the elimination threshold (3)" do
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
    
    it "should return false if the string is in the 'negative voted by' list" do
      @nomination.stub!(:negative_votes).and_return [Vote.new(:ip => "me")]
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
  
  describe "down votes necessary" do
    before do
      @nomination = Nomination.new
      @nomination.stub!(:votes).and_return []
      @nomination.stub!(:down_votes).and_return []
    end
    
    it "should use 1 as the default value if dont have any 'up'-votes" do
      @nomination.down_votes_necessary.should == 1
    end
    
    it "should use the number of 'up'-votes if we got some" do
      @nomination.stub!(:votes).and_return [Vote.new, Vote.new, Vote.new, Vote.new]
      @nomination.down_votes_necessary.should == 4
    end
    
    it "should return the default value if we dont have any down votes yet" do
      @nomination.down_votes_necessary.should == 1
    end
    
    it "should subtract the sum of the down votes if we have down votes" do
      @nomination.stub!(:down_votes).and_return [Vote.new(:value => 1), Vote.new(:value => 3)]
      @nomination.down_votes_necessary.should == -3
    end
  end
  
  describe "force" do
    before do
      @nomination = Nomination.new(:nominated_by => "me")
      @nomination.stub!(:negative_votes).and_return [Vote.new(:ip => "me")]
      @nomination.down_votes.stub!(:create).and_return true
    end
    
    it "should create an associated force vote with the ip" do
      @nomination.down_votes.should_receive(:create).with :value => 1, :ip => "me", :type => "force"
      @nomination.force "me"
    end
    
    it "should not allow a vote, if we have already forced" do
      @nomination.down_votes.should_receive(:create).once
      2.times { @nomination.force "me" }
    end
    
    it "should not play the next album if we have a 'force score' of 1 or more" do
      @nomination.stub!(:down_votes_necessary).and_return 1
      MpdProxy.should_not_receive :execute
      @nomination.force "me"
    end
    
    it "should play the next album if we have a 'force score' of 0 or less" do
      @nomination.stub!(:down_votes_necessary).and_return 0
      MpdProxy.should_receive(:execute).with :clear
      @nomination.force "me"
    end
  end
  
  describe "can be forced by?" do
    before do
      @nomination = Nomination.new
      @nomination.stub!(:negative_votes).and_return [Vote.new(:ip => "me")]
    end
    
    it "should return true if the force votes dont contain a vote by the given 'user' and if the user has put a negative vote on the nomination" do
      @nomination.can_be_forced_by?("me").should be_true
    end
    
    it "should return false if the string is in the 'down votes' list" do
      @nomination.stub!(:down_votes).and_return [Vote.new(:ip => "me")]
      @nomination.can_be_forced_by?("me").should be_false
    end
    
    it "should return false if the string is not in the 'negative voted by' list" do
      @nomination.stub!(:negative_votes).and_return []
      @nomination.can_be_forced_by?("me").should be_false
    end
    
    it "should return false if we have a force vote but not a negative vote from the user" do
      @nomination.stub!(:down_votes).and_return [Vote.new(:ip => "me")]
      @nomination.stub!(:negative_votes).and_return []
      
      @nomination.can_be_forced_by?("me").should be_false
    end
  end
  
  describe "rate" do
    before do
      @nomination = Nomination.new(:nominated_by => "me")
      @nomination.ratings.stub!(:create).and_return true
      @nomination.stub! :update_attributes
    end
    
    it "should create an associated rating with the ip" do
      @nomination.ratings.should_receive(:create).with :value => 4, :ip => "me", :type => "rating"
      @nomination.rate 4, "me"
    end

    { -1 => 1, 0 => 1, 6 => 5 }.each do |param, value|
      it "should change the param #{param} to #{value}" do
        @nomination.ratings.should_receive(:create).with :value => value, :ip => "me", :type => "rating"
        @nomination.rate param, "me"
      end
    end
    
    it "should not allow a rating, if we have already rated" do
      @nomination.ratings.should_receive(:create).once
      2.times { @nomination.rate 1, "me" }
    end
  end
  
  describe "can be rated by?" do
    before do
      @nomination = Nomination.new
    end
    
    it "should return true if the force votes dont contain a vote by the given 'user'" do
      @nomination.can_be_rated_by?("me").should be_true
    end
    
    it "should return false if the string is in the 'forced by' list" do
      @nomination.stub!(:ratings).and_return [Vote.new(:ip => "me")]
      @nomination.can_be_rated_by?("me").should be_false
    end
  end
  
  describe "active" do
    before do
      @nomination = Nomination.new
      Nomination.stub!(:all).and_return [@nomination]
    end
    
    it "should grab all nominations that are voteable" do
      Nomination.should_receive(:all).with(:status => "active", :order => [:score.desc, :created_at]).and_return [@nomination]
      Nomination.active.should == [@nomination]
    end
  end
  
  describe "played" do
    before do
      @nomination = Nomination.new
      Nomination.stub!(:all).and_return [@nomination]
    end
    
    it "should grab all nominations that have been played" do
      Nomination.should_receive(:all).with(:status => "played", :order => [:played_at.desc]).and_return [@nomination]
      Nomination.played.should == [@nomination]
    end
  end
  
  describe "current" do
    before do
      @nomination = Nomination.new
      Nomination.stub! :played
    end
    
    it "should return the first album flagged as 'played' ordered by 'played_at' attribute" do
      Nomination.should_receive(:played).and_return [@nomination]
      Nomination.current.should == @nomination
    end
  end
end