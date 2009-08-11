require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Library do
  
  describe "lib" do
    before do
      Library.stub! :create
    end
    
    it "should return the first Library in the DB if we have one" do
      Library.stub!(:first).and_return lib = Library.new
      Library.lib.should == lib
    end
    
    it "should create a new Library record if we cant find a record in the DB" do
      Library.should_receive(:create).and_return lib = Library.new
      Library.lib.should == lib
    end
  end
  
  describe "update albums" do
    before do
      MpdConnection.stub!(:fetch_new_albums_with_artists).and_return []
      
      Library.stub!(:lib).and_return @lib = Library.new
      @lib.stub!(:albums).and_return @list = [Album.new(:artist => "a", :name => "name")]
    end
    
    it "should fetch all new albums from the mpd connection" do
      MpdConnection.should_receive(:fetch_new_albums_with_artists).with([["a", "name"]]).and_return []
      Library.update_albums
    end
    
    it "should not create anything if we have an empty list" do
      @lib.albums.should_not_receive :create
      Library.update_albums
    end
    
    it "should create an album in the database for each returned artist - album combination" do
      MpdConnection.stub!(:fetch_new_albums_with_artists).and_return [["artist", "album"]]
      @lib.albums.should_receive(:create).with :artist => "artist", :name => "album"
      Library.update_albums
    end
  end
  
  describe "current song callback" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new
      Library.stub! :play_next
      @lib.stub! :update_attributes
      
      @song = MPD::Song.new
      { "artist" => "me", "title" => "song", "album" => "hits" }.each { |k, v| @song[k] = v }
    end
    
    it "should update the song variable" do
      @lib.should_receive(:update_attributes).with :current_song => "me - song (hits)"
      Library.current_song_callback @song
    end
    
    it "should set it to nil if we get nothing" do
      @lib.should_receive(:update_attributes).with :current_song => nil
      Library.current_song_callback nil
    end
    
    it "should load next album" do
      Library.should_receive :play_next
      Library.current_song_callback nil
    end
    
    it "should not load the next album if we are currently playing something" do
      Library.stub!(:playing?).and_return true
      Library.should_not_receive :play_next
      Library.current_song_callback @song
    end
  end
  
  describe "volume callback" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new
      @lib.stub! :update_attributes
    end
    
    it "should update the volume attribute of the lib" do
      @lib.should_receive(:update_attributes).with :volume => 53
      Library.volume_callback 53
    end
  end
  
  describe "playing?" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new
    end
    
    it "should return false if no current song is playing" do
      Library.should_not be_playing
    end
    
    it "should return true if we have a current song playing" do
      @lib.current_song = "some song"
      Library.should be_playing
    end
  end
  
  describe "play next" do
    before do
      MpdConnection.stub! :play_album
      
      Library.stub!(:lib).and_return @lib = Library.new
      @lib.played_albums.stub!(:create).and_return true
      
      album = Album.new(:name => "my name")
      @next = @lib.voteable_albums.build(:album => album, :created_at => Time.now)
      @next.stub! :destroy
    end
    
    it "should do nothing if we dont have an upcoming album" do
      @lib.voteable_albums = []
      MpdConnection.should_not_receive :play_album
      Library.play_next
    end
    
    it "should play the first album in the upcoming list" do
      MpdConnection.should_receive(:play_album).with @next.name
      Library.play_next
    end
    
    it "should create a played album record" do
      @lib.played_albums.should_receive(:create).with :album => @next.album
      Library.play_next
    end
    
    it "should destroy the album added to the playlist" do
      @next.should_receive :destroy
      Library.play_next
    end
  end
  
  describe "force" do
    before do
      Library.stub!(:current).and_return @p_album = PlayedAlbum.new
      Library.stub! :play_next
      
      @p_album.stub! :vote
    end
    
    it "should do nothing if we dont have a currently playing album right now" do
      Library.stub! :current
      @p_album.should_not_receive :vote
      Library.force "me"
    end
    
    it "should add a voting to the currently played album" do
      @p_album.should_receive(:vote).with 1, "me"
      Library.force "me"
    end
    
    it "should not play the next album if we have a remaining number > 0" do
      Library.should_not_receive :play_next
      Library.force "me"
    end
    
    it "should play the next album if the remaining attribute of the played album is (less than) 0" do
      @p_album.stub!(:remaining).and_return 0
      Library.should_receive :play_next
      Library.force "me"
    end
  end
  
  describe "albums list" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new
    end
    
    it "should sort the list by artist and then album name" do
      @lib.albums.build :artist => "b", :name => "b"
      @lib.albums.build :artist => "b", :name => "a"
      @lib.albums.build :artist => "a", :name => "c"
      
      Library.list[0].name.should == "c"
      Library.list[1].name.should == "a"
    end
  end
  
  describe "upcoming albums" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new
      @album = Album.new(:artist => "artist", :name => "album")
    end
    
    it "should provide read and add methods for 'next'" do
      Library.should respond_to(:upcoming)
      Library.should respond_to(:<<)
    end
    
    it "should add an album to the upcoming albums when '<<' is called" do
      Time.stub!(:now).and_return "now"
      @lib.voteable_albums.should_receive(:create).with :album => @album, :created_at => "now"
      Library << @album
    end
    
    it "should sort the list by number of votes and date of creation then" do
      album1 = mock("Album", :rating => 1, :created_at => Time.now - 3600)
      album2 = mock("Album", :rating => 2, :created_at => Time.now)
      album3 = mock("Album", :rating => 1, :created_at => Time.now)
      @lib.stub!(:voteable_albums).and_return [album1, album2, album3]
      
      Library.upcoming.should == [album2, album1, album3]
    end
  end
  
  describe "current album" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new
      Library.stub!(:playing?).and_return true
      
      @lib.played_albums.stub!(:first).and_return "album1"
    end
    
    it "should return the first album in the played albums list" do
      Library.current.should == "album1"
    end
    
    it "should return nil if we arent playing anything right now" do
      Library.stub! :playing?
      Library.current.should be_nil
    end
  end
  
  describe "volume" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new
      @lib.volume = 45
    end
    
    it "should return the volume of the lib instance" do
      Library.volume.should == 45
    end
  end
  
  describe "search" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new
      @lib.albums.build :artist => "artist", :name => "hits"
      
      MpdConnection.stub!(:find_albums_for).and_return []
    end
    
    it "should return the complete list if we have a nil query" do
      Library.search(nil).should == Library.list
    end
    
    it "should return the complete list if we have a blank query" do
      Library.search("").should == Library.list
    end
    
    it "should use the MPD server to search for matching albums" do
      MpdConnection.should_receive(:find_albums_for).with "query"      
      Library.search "query"
    end
    
    it "should return an empty array if we cant find anything" do
      Library.search("query").should be_empty
    end
    
    it "should return an empty array if we found something but dont have a (matching) album in the list" do
      @lib.albums = []
      MpdConnection.stub!(:find_albums_for).and_return ["other"]
      Library.search("query").should be_empty
    end
    
    it "should match the found songs against the album list and return the matches" do
      MpdConnection.stub!(:find_albums_for).and_return ["hits"]
      Library.search("query").should == Library.list
    end
  end
end