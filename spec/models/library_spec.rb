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
  
  describe "fetch albums" do
    before do
      MpdConnection.stub!(:fetch_albums_with_artists).and_return []
      
      Library.stub!(:lib).and_return @lib = Library.new
      @lib.albums.stub! :destroy!
    end
    
    it "should remove all existing albums in the database" do
      @lib.albums.should_receive :destroy!
      Library.fetch_albums
    end
    
    it "should fetch all albums from the mpd connection" do
      MpdConnection.should_receive(:fetch_albums_with_artists).and_return []
      Library.fetch_albums
    end
    
    it "should not create anything if we have an empty list" do
      @lib.albums.should_not_receive :create
      Library.fetch_albums
    end
    
    it "should create an album in the database for each returned artist - album combination" do
      MpdConnection.stub!(:fetch_albums_with_artists).and_return [["artist", "album"]]
      @lib.albums.should_receive(:create).with :artist => "artist", :name => "album"
      Library.fetch_albums
    end
  end
  
  describe "current song callback" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new
      @lib.stub! :update_attributes; @lib.stub! :play_next
      
      @song = MPD::Song.new
      { "artist" => "me", "title" => "song", "album" => "hits" }.each { |k, v| @song[k] = v }
    end
    
    it "should update the song variable" do
      @lib.should_receive(:update_attributes).with :current_song => "me - song (hits)"
      Library.current_song_callback @song
    end
    
    it "should set it to nil if we get nothing" do
      @lib.should_receive(:update_attributes).with :current_song => ""
      Library.current_song_callback nil
    end
    
    it "should load next album if the song is nil (no next song in the playlist)" do
      Library.should_receive :play_next
      Library.current_song_callback nil
    end
  end
  
  describe "play next" do
    before do
      MpdConnection.stub! :play_album
      
      Library.stub!(:lib).and_return @lib = Library.new
      @next = @lib.voteable_albums.build(:name => "my album")
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
    
    it "should destroy the album added to the playlist" do
      @next.should_receive :destroy
      Library.play_next
    end
  end
  
  describe "current song" do
    before do
      Library.stub!(:lib).and_return @lib = Library.new(:current_song => "my song")
    end
    
    it "should return the value of the current son attribute of the lib instance" do
      Library.current_song.should == "my song"
    end
  end
  
  describe "albums accessor" do
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
      @lib.voteable_albums.should_receive(:create).with :artist => "artist", :name => "album"
      Library << @album
    end
    
    it "should sort the list by number of votes" do
      album1 = mock("Album", :votes => 1)
      album2 = mock("Album", :votes => 2)
      @lib.stub!(:voteable_albums).and_return [album1, album2]
      
      Library.upcoming.should == [album2, album1]
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