require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Album do
  
  describe "to hash" do
    before do
      @album = Album.new(:id => 123, :artist => "artist", :name => "album")
    end
    
    it "should map all attributes into a hash" do
      @album.to_hash.should == { :id => 123, :artist => "artist", :name => "album" }
    end
  end
  
  describe "update" do
    before do
      @song = MPD::Song.new
      { "track" => 1, "artist" => "me", "title" => "song", "album" => "album1", "file" => "path" }.each { |k, v| @song[k] = v }
      
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
      @album.songs.should_receive(:build).with :track => 1, :artist => "me", :title => "song", :file => "path"
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
  
  describe "current" do
    before do
      Album.stub!(:first).and_return "album1"
    end
    
    it "should return the first album (ordered by last_played_at DESC)" do
      Album.should_receive(:first).with(:order => :last_played_at.desc).and_return "album1"
      Album.current.should == "album1"
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
      Album.should_receive(:all).with(:conditions => ["artist LIKE :q OR name LIKE :q", "%query%"]).and_return @list
      Album.search("query").should == @list
    end
  end
end