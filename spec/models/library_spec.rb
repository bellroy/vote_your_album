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
      
      Library.stub!(:playing?).and_return true
      Library.stub!(:current_song).and_return @song = Song.new
      @song.stub! :update_attributes
      
      Library.stub!(:playlist).and_return []
      
      @mpd_song = MPD::Song.new
      { "artist" => "me", "title" => "song", "album" => "hits" }.each { |k, v| @mpd_song[k] = v }
    end
    
    it "should reset the 'playing' flag of the current_song if we have one" do
      @song.should_receive(:update_attributes).with :playing => false
      Library.current_song_callback nil
    end
    
    it "should not reset the 'playing' flag if we arent playing anything right now" do
      Library.stub!(:playing?).and_return false
      @song.should_not_receive :update_attributes
      
      Library.current_song_callback nil
    end
    
    describe "new song is nil" do
      before do
        @lib.last_album_load = Time.now - 120
      end
      
      it "should not try to set the 'playing' flag" do
        Library.should_not_receive :playlist
        Library.current_song_callback nil
      end
      
      it "should load next album if we havent loaded an album in the last minute" do
        Library.should_receive :play_next
        Library.current_song_callback nil
      end
      
      it "should not load next album if we have loaded an album within the last minute" do
        @lib.last_album_load = Time.now - 10
        Library.should_not_receive :play_next
        Library.current_song_callback nil
      end
      
      it "should load next album if we havent loaded an album at all" do
        @lib.last_album_load = nil
        Library.should_receive :play_next
        Library.current_song_callback nil
      end
    end

    describe "new song is not nil" do
      before do
        @song1 = Song.new(:artist => "me", :title => "other")
        @song2 = Song.new(:artist => "me", :title => "song")
        @song.stub! :update_attributes
        
        Library.stub!(:playlist).and_return [@song1, @song2]
      end
           
      it "should set the 'playing' flag for the matching artist and album from the playlist" do
        @song2.should_receive(:update_attributes).with :playing => true
        Library.current_song_callback @mpd_song
      end
      
      it "should not set a 'playing' flag if we cant find a matching song" do
        @mpd_song["title"] = "title"
        @song2.should_not_receive :update_attributes
        
        Library.current_song_callback @mpd_song
      end
      
      it "should not load the next album" do
        Library.should_not_receive :play_next
        Library.current_song_callback @mpd_song
      end
    end
  end
  
  describe "playlist callback" do
    before do
      Library.stub! :current_song_callback
      Library.stub!(:lib).and_return @lib = Library.new
      @lib.songs.stub! :destroy!
      
      MpdConnection.stub!(:execute).with :current_song
      MpdConnection.stub!(:execute).with(:playlist).and_return []
      @song1 = MPD::Song.new
      @song2 = MPD::Song.new
    end
    
    it "should do nothing if we have a version of 0" do
      @lib.songs.should_not_receive :destroy!
      Library.playlist_callback 0
    end
    
    it "should destroy all songs related to the current library" do
      @lib.songs.should_receive :destroy!
      Library.playlist_callback 1
    end
    
    it "should create new songs in the database for the given MPD::Song's" do
      MpdConnection.stub!(:execute).with(:playlist).and_return [@song1, @song2]
      Song.should_receive(:create_from_mpd).with @lib, @song1
      Song.should_receive(:create_from_mpd).with @lib, @song2
      
      Library.playlist_callback 1
    end
    
    it "should ask the MPD server for the currently played song" do
      MpdConnection.should_receive(:execute).with(:current_song).and_return @song1
      Library.should_receive(:current_song_callback).with @song1
      Library.playlist_callback 1
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
  
  describe "play next" do
    before do
      MpdConnection.stub! :play_album
      
      Library.stub!(:lib).and_return @lib = Library.new
      @lib.played_albums.stub!(:create).and_return true
      @lib.stub! :update_attributes
      
      album = Album.new(:name => "my name")
      @next = @lib.nominations.build(:album => album, :created_at => Time.now)
      @next.stub! :destroy
    end
    
    it "should do nothing if we dont have an upcoming album" do
      @lib.nominations = []
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
    
    it "should update the 'last album load' attribute of the library" do
      Time.stub!(:now).and_return @time = mock("Now", :tv_sec => 1)
      @lib.should_receive(:update_attributes).with :last_album_load => @time
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
      @lib.nominations.should_receive(:create).with :album => @album, :created_at => "now", :added_by => "me"
      Library.<< @album, "me"
    end
    
    it "should sort the list by number of votes and date of creation then" do
      album1 = mock("Album", :score => 1, :created_at => Time.now - 3600)
      album2 = mock("Album", :score => 2, :created_at => Time.now)
      album3 = mock("Album", :score => 1, :created_at => Time.now)
      @lib.stub!(:nominations).and_return [album1, album2, album3]
      
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
  
  describe "playlist" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new
      @lib.stub!(:songs).and_return @list = ["one", "two"]
    end
    
    it "should return the songs associated with the current library" do
      Library.playlist.should == @list
    end
  end
  
  describe "current song" do
    before do
      Library.stub!(:playlist).and_return []
      
      @song1 = Song.new
      @song2 = Song.new
    end
    
    it "should return nil if we dont any songs in the playlist" do
      Library.current_song.should be_nil
    end
    
    it "should return nil if we dont have any songs with the 'playing' flag" do
      Library.stub!(:playlist).and_return [@song1, @song2]
      Library.current_song.should be_nil
    end
    
    it "should return the song with the 'playing' flag set" do
      Library.stub!(:playlist).and_return [@song1, @song2]
      @song2.playing = true
      
      Library.current_song.should == @song2
    end
  end
  
  describe "playing?" do
    it "should return false if no current song is playing" do
      Library.should_not be_playing
    end
    
    it "should return true if we have a current song playing" do
      Library.stub!(:current_song).and_return Song.new
      Library.should be_playing
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