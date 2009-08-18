require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Album do
  
  describe "play count" do
    before do
      @album = Album.new
      @album.nominations.stub!(:played).and_return [1, 2, 3]
    end
    
    it "should return the number of associated played nominations" do
      @album.play_count.should == 3
    end
  end
  
  describe "score" do
    before do
      @album = Album.new
      @album.stub!(:nominations).and_return [Nomination.new(:score => 3), Nomination.new(:score => -1)]
    end
    
    it "should return the summed up score of all nominations" do
      @album.score.should == 2
    end
    
    it "should return 0 if we dont have a nomination" do
      @album.stub!(:nominations).and_return []
      @album.score.should == 0
    end
  end
  
  describe "rating" do
    before do
      @nom1 = Nomination.new; @nom1.stub!(:ratings).and_return [Vote.new(:value => 1), Vote.new(:value => 2)]
      @nom2 = Nomination.new; @nom2.stub!(:ratings).and_return [Vote.new(:value => 5)]
      @nom3 = Nomination.new; @nom3.stub!(:ratings).and_return []
      
      @album = Album.new
      @album.stub!(:nominations).and_return []
    end
    
    it "should return 0 if we dont have any nominations" do
      @album.rating.should == 0
    end
    
    it "should return 0 if we only have nomination without ratings" do
      @album.stub!(:nominations).and_return [@nom3]
      @album.rating.should == 0
    end
    
    it "should return the rounded value of the rating average" do
      @album.stub!(:nominations).and_return [@nom1, @nom2, @nom3]
      @album.rating.should == (8.to_f / 3 * 10).round / 10.0
    end
  end
  
  describe "to s" do
    before do
      @album = Album.new(:id => 123, :artist => "artist", :name => "album")
    end
    
    it "should return the artist and name in a string" do
      @album.to_s.should == "artist - album"
    end
  end
  
  describe "update" do
    before do
      @song = MPD::Song.new
      { "track" => "1", "artist" => "me", "title" => "song", "album" => "album1", "file" => "path" }.each { |k, v| @song[k] = v }
      
      MpdProxy.stub!(:execute).with(:songs).and_return @songs = [@song]
      MpdProxy.stub!(:execute).with(:albums).and_return ["album1"]
      
      Album.stub! :first
      
      @album = Album.new
      Album.stub!(:new).and_return @album
      @album.stub! :save
      @album.songs.stub!(:first).and_return @song
    end
    
    it "should fetch all songs from the server" do
      MpdProxy.should_receive(:execute).with(:songs).and_return @songs
      Album.update
    end
    
    it "should fetch all albums from the server" do
      MpdProxy.should_receive(:execute).with(:albums).and_return []
      Album.update
    end
    
    it "should not do anything if we already have that album in the DB" do
      Album.should_receive(:first).with(:name => "album1").and_return "exists!"
      Album.should_not_receive :build
      Album.update
    end
    
    it "should build a new album if we dont know it yet" do
      Album.should_receive(:new).with(:name => "album1").and_return @album
      Album.update
    end
    
    it "should fetch all the songs for that album from the list of songs" do
      @album.songs.should_receive(:build).with :track => "1", :artist => "me", :title => "song", :file => "path"
      Album.update
    end
    
    it "should not add a song if we dont have matching album names" do
      song2 = MPD::Song.new
      { "track" => 2, "artist" => "me", "title" => "song", "album" => "album2", "file" => "other" }.each { |k, v| song2[k] = v }
      @songs = [@song, song2]
      
      @album.songs.should_not_receive(:build).with :track => 2
      Album.update
    end
    
    it "should get the name of the artist for the album from the songs" do
      @album.should_receive(:artist=).with "me"
      Album.update
    end
    
    it "should not use a nil artist if we have a non-nil artist in the song list" do
      song2 = MPD::Song.new
      { "track" => 2, "artist" => "me", "title" => "song", "album" => "album1", "file" => "other" }.each { |k, v| song2[k] = v }
      MpdProxy.stub!(:execute).with(:songs).and_return [song2, @song]
      
      @album.should_receive(:artist=).with "me"
      Album.update
    end
    
    it "should assign a empty value instead of a nil value if we dont have any artists" do
      @song["artist"] = nil
      @album.should_receive(:artist=).with ""
      Album.update
    end
    
    it "should take the artist that is the shortest" do
      @song["artist"] = "MJ Feat. someone"
      song2 = MPD::Song.new
      { "track" => 2, "artist" => "MJ", "title" => "song", "album" => "album1", "file" => "other" }.each { |k, v| song2[k] = v }
      song3 = MPD::Song.new
      { "track" => 3, "artist" => "MJ & DJ", "title" => "song", "album" => "album1", "file" => "other" }.each { |k, v| song3[k] = v }
      MpdProxy.stub!(:execute).with(:songs).and_return [@song, song2, song3]
      
      @album.should_receive(:artist=).with "MJ"
      Album.update
    end
    
    it "should save the new album" do
      @album.should_receive :save
      Album.update
    end
  end
  
  describe "search" do
    before do
      Album.stub!(:all).and_return @list = ["one", "two"]
    end
  
    it "should return the complete list if we have a nil query" do
      Album.search(nil).should == @list
    end
  
    it "should return the complete list if we have a blank query" do
      Album.search("").should == @list
    end
    
    it "should return the result of a DB search if we have a query" do
      Album.should_receive(:all).with(:conditions => ["artist LIKE ? OR name LIKE ?", "%query%", "%query%"]).and_return @list
      Album.search("query").should == @list
    end
  end
  
  { :most_listened => :play_count, :most_popular => :score, :top_rated => :rating }.each do |method, criteria|
    describe method do
      before do
        @album1 = Album.new(:id => 1); @album1.stub!(criteria).and_return 1
        @album2 = Album.new(:id => 2); @album2.stub!(criteria).and_return 4
        @album3 = Album.new(:id => 3); @album3.stub!(criteria).and_return 0
        Album.stub!(:all).and_return @list = [@album1, @album2, @album3]
      end

      it "should grab the albums" do
        Album.should_receive(:all).and_return @list
        Album.send method
      end

      it "should remove all albums with a #{criteria} equal to" do
        Album.send(method).should_not include(@album3)
      end

      it "should then sort the list by the #{criteria} value" do
        Album.send(method).first.should == @album2
      end
    end
  end
  
  describe "value method for" do
    { "most_listened" => :play_count, "most_popular" => :score, "top_rated" => :rating,
      "all" => nil, "bla" => nil }.each do |scope, method|
      it "should return the method name '#{method}' for the scope '#{scope}'" do
        Album.value_method_for(scope).should == method
      end
    end
  end
end