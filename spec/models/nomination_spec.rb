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

  describe "ttl" do
    before do
      @nomination = Nomination.new
    end

    it "should return nil if we dont have a expires at time" do
      @nomination.ttl.should be_nil
    end

    it "should return the difference between now and the expires at time in seconds" do
      @nomination.expires_at = Time.now + 121
      @nomination.ttl.should == 120
    end
  end

  describe "owned by?" do
    before do
      @user = User.new
      @nomination = Nomination.new(:user => @user)
    end

    it "should return fals if we dont have a user" do
      @nomination.user = nil
      @nomination.should_not be_owned_by(@user)
    end

    it "should return true if we have nominated the album" do
      @nomination.should be_owned_by(@user)
    end

    it "should return false if haven't nominated the album" do
      @nomination.should_not be_owned_by(User.new(:id => 123))
    end
  end

  describe "score_s" do
    it "should return '0' if the score is 0" do
      Nomination.new(:score => 0).score_s.should == "0"
    end

    it "should return '+*' if the score is > 0" do
      Nomination.new(:score => 1).score_s.should == "+1"
      Nomination.new(:score => 3).score_s.should == "+3"
      Nomination.new(:score => 5).score_s.should == "+5"
    end

    it "should return '-*' if the score is < 0" do
      Nomination.new(:score => -1).score_s.should == "-1"
      Nomination.new(:score => -3).score_s.should == "-3"
      Nomination.new(:score => -5).score_s.should == "-5"
    end
  end

  describe "nominated by" do
    before do
      @nomination = Nomination.new
    end

    it "should return 'Dr Random' if we don't have a user" do
      @nomination.nominated_by.should == "Dr Random"
    end

    it "should return the name of the user otherwise" do
      user = User.new(:name => "blubbi")
      @nomination.user = user

      @nomination.nominated_by.should == "blubbi"
    end
  end

  describe "vote" do
    before do
      @user = User.create(:identifier => "awesome@example.com")
      @album = Album.create(:artist => "Arctic", :name => "Monkeys")

      @nomination = Nomination.create(:album => @album, :user => @user, :status => "active")
      # @nomination.votes.stub!(:create).and_return @vote
      # @nomination.negative_votes.stub!(:create).and_return @vote
      # @nomination.stub! :save

      Update.stub! :log
    end

    it "should create an associated vote with the given value and ip" do
      @nomination.vote 1, @user
      @nomination.votes.should_not be_empty
    end

    it "should create an associated negative vote with the given (negative) value and ip" do
      @nomination.vote -1, @user
      @nomination.negative_votes.should_not be_empty
    end

    it "should update the score attribute" do
      @nomination.vote 2, @user
      @nomination.score.should == 2
    end

    it "should not allow a vote, if we have already voted" do
      2.times { @nomination.vote 1, @user }
      @nomination.votes.size.should == 1
    end

    describe "eliminate" do
      it "should not change the status to 'deleted' when the threshold isnt reached" do
        @nomination.stub!(:score).and_return -2
        @nomination.vote -2, @user
        @nomination.status.should == "active"
      end

      it "should change the status to 'deleted' when we have reached the elimination threshold (3)" do
        @nomination.stub!(:score).and_return -3
        @nomination.vote -3, @user
        @nomination.status.should == "deleted"
      end
    end

    describe "expires at" do
      describe "with a negative score" do
        before do
          @nomination.stub!(:score).and_return -1
        end

        it "should be set if we have a negative score and its nil" do
          @nomination.vote -2, @user
          @nomination.ttl.should_not be_nil
        end

        it "should not be set if we already have set it before" do
          @nomination.stub!(:ttl).and_return "not nil"
          @nomination.vote -2, @user
          @nomination.expires_at.should be_nil
        end
      end

      describe "with a positive or neutral score" do
        before do
          @nomination.stub!(:score).and_return 1
        end

        it "should be reset if it is currently set" do
          @nomination.expires_at = Time.now
          @nomination.vote 2, @user
          @nomination.ttl.should be_nil
        end

        it "should do nothing if its not set" do
          @nomination.vote 2, @user
          @nomination.expires_at.should be_nil
        end
      end
    end
  end

  describe "can be voted for by?" do
    before do
      @user = User.new
      @nomination = Nomination.new
    end

    it "should return true if the votes dont contain a vote by the given 'user'" do
      @nomination.can_be_voted_for_by?(@user).should be_true
    end

    it "should return false if the user is in the 'voted by' list" do
      @nomination.stub!(:votes).and_return [Vote.new(:user => @user)]
      @nomination.can_be_voted_for_by?(@user).should be_false
    end

    it "should return false if the user is in the 'negative voted by' list" do
      @nomination.stub!(:negative_votes).and_return [Vote.new(:user => @user)]
      @nomination.can_be_voted_for_by?(@user).should be_false
    end
  end

  describe "remove" do
    before do
      @user = User.new
      @nomination = Nomination.new(:user => @user)
      @nomination.stub! :update

      Update.stub! :log
    end

    it "should do nothing if we havent nominated the album" do
      @nomination.should_not_receive :update
      @nomination.remove User.new(:id => 123)
    end

    it "should set the status to 'deleted' when we are the owner" do
      @nomination.should_receive(:update).with :status => "deleted"
      @nomination.remove @user
    end
  end

  describe "down votes necessary" do
    before do
      @nomination = Nomination.new
      @nomination.stub!(:score).and_return 0
    end

    it "should use 2 as the default value if we have a score of 0" do
      @nomination.down_votes_necessary.should == 2
    end

    it "should use the score + 2 as the base value" do
      @nomination.stub!(:score).and_return 2
      @nomination.down_votes_necessary.should == 4
    end

    it "should use 1 if the score + 2 is zero or less" do
      @nomination.stub!(:score).and_return -2
      @nomination.down_votes_necessary.should == 1
    end
  end

  describe "force" do
    before do
      @album = Album.create(:artist => "Arctic", :name => "Monkeys")
      @user = User.create(:identifier => "awesome@example.com")

      @nomination = Nomination.create(:album => @album, :user => @user, :status => "active")

      Update.stub! :log
    end

    it "should create an associated force vote with the ip" do
      @nomination.force @user
      @nomination.down_votes.should_not be_empty
    end

    it "should not allow a vote, if we have already forced" do
      2.times { @nomination.force @user }
      @nomination.down_votes.size.should == 1
    end

    it "should not play the next album if we have a 'force score' of 1 or more" do
      @nomination.stub!(:down_votes_necessary).and_return 1
      MpdProxy.should_not_receive :execute
      @nomination.force @user
    end

    it "should play the next album if we have a 'force score' of 0 or less" do
      @nomination.stub!(:down_votes_necessary).and_return 0
      MpdProxy.should_receive(:execute).with :clear
      @nomination.force @user
    end
  end

  describe "can be forced by?" do
    before do
      @user = User.new
      @nomination = Nomination.new
    end

    it "should return true if the force votes dont contain a vote by the given user" do
      @nomination.can_be_forced_by?(@user).should be_true
    end

    it "should return false if the user is in the 'down votes' list" do
      @nomination.stub!(:down_votes).and_return [Vote.new(:user => @user)]
      @nomination.can_be_forced_by?(@user).should be_false
    end
  end

  describe "active" do
    before do
      @nomination = Nomination.new
      Nomination.stub!(:all).and_return [@nomination]
      Nomination.stub! :clean
    end

    it "should clean the list before returning it" do
      Nomination.should_receive :clean
      Nomination.active
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

  describe "clean" do
    before do
      @nomination = Nomination.new
      @nomination.stub! :update

      Nomination.stub!(:all).and_return [@nomination]
    end

    it "should not set the status to 'deleted' when we have time left" do
      @nomination.stub!(:ttl).and_return 123
      @nomination.should_not_receive :update
      Nomination.clean
    end

    it "should set the status to 'deleted' when the nomination has expired" do
      @nomination.stub!(:ttl).and_return 0
      @nomination.should_receive(:update).with :status => "deleted"
      Nomination.clean
    end
  end
end