shared_examples_for "it belongs to an album" do
  describe "album accessors" do
    before do
      @album = Album.new(:artist => "artist", :name => "album")
      @v_album = clazz.new(:album => @album)
    end
    
    it "should return the artist of the album" do
      @v_album.artist.should == "artist"
    end
    
    it "should return the album name of the album" do
      @v_album.name.should == "album"
    end
  end
  
  describe "rating" do
    before do
      @album = clazz.new
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
      @album = clazz.new
      @album.votes.stub! :create
      @album.votes.stub! :reload
    end
    
    it "should create an associated vote with the given value and ip" do
      @album.votes.should_receive(:create).with :value => 1, :ip => "me"
      @album.vote 1, "me"
    end
    
    it "should not allow a vote, if we have already voted" do
      @album.votes.should_receive(:create).once
      2.times { @album.vote 1, "me" }
    end
    
    it "should not destroy the record no many how low the rating is" do
      @album.should_not_receive :destroy
      @album.vote -5, "me"
    end
    
    describe "eliminate" do
      before do
        @album.stub! :destroy
      end
      
      it "should not destroy itself when the threshold for elimination isnt reached" do
        @album.should_not_receive :destroy
        @album.vote -2, "me", true
      end

      it "should destroy itself when we have reached the elimination threshold (ELIMINATION_RATING)" do
        @album.should_receive :destroy
        @album.vote -3, "me", true
      end
    end
  end
  
  describe "can be voted for by?" do
    before do
      @album = clazz.new
    end
    
    it "should return true if the votes dont contain a vote by the given 'user'" do
      @album.can_be_voted_for_by?("me").should be_true
    end
    
    it "should return false if the string is in the 'voted by' list" do
      @album.stub!(:votes).and_return [Vote.new(:ip => "me")]
      @album.can_be_voted_for_by?("me").should be_false
    end
  end
end