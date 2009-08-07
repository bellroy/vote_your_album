require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Library do
  
  describe "setup" do
    before do
      Library.class_eval do
        @list, @song = [], nil
      end
      
      MPD.stub!(:new).and_return @mpd = mock("MPD", :connect => nil, :register_callback => nil, :albums => [], :current_song => nil)
    end
    
    it "should get a new connection to the MPD server" do
      MPD.should_receive(:new).with("mpd", 6600).and_return @mpd
      @mpd.should_receive(:connect).with true
      
      Library.setup
    end
    
    it "should register a callback for the 'current song'" do
      @mpd.should_receive(:register_callback).with Library.method("current_song_callback"), MPD::CURRENT_SONG_CALLBACK
      Library.setup
    end
    
    describe "albums" do
      before do
        @mpd.stub!(:find).and_return []
      end
      
      it "should grab the complete list from the MPD server" do
        @mpd.should_receive(:albums).and_return ["first", "second"]
        Library.setup

        Library.list.size.should == 2
      end
      
      it "should try to get the artist, by searching for songs with that exact album name" do
        @mpd.stub!(:albums).and_return ["first"]
        @mpd.should_receive(:find).with("album", "first").and_return []
        
        Library.setup
      end
      
      it "should assign the first songs artist aas the album artist" do
        @mpd.stub!(:albums).and_return ["first"]
        
        @song = MPD::Song.new
        { "artist" => "me", "title" => "song", "album" => "hits" }.each { |k, v| @song[k] = v }
        @mpd.stub!(:find).and_return [@song]
        
        Library.setup
        Library.list.first.artist.should == "me"
      end
    end
    
    it "should get the currently played song from the server" do
      @mpd.should_receive(:current_song).and_return nil
      Library.setup
      
      Library.song.should == ""
    end
    
    it "should start by being disabled" do
      Library.setup
      Library.should_not be_enabled
    end
  end
  
  describe "list" do
    before do
      Library.class_eval do
        @list = []
      end
    end
    
    it "should provide read and write methods for 'list'" do
      Library.should respond_to(:list)
      Library.should respond_to(:list=)
    end
    
    it "should sort the list by album name" do
      Library.list = [Album.new(1, "b", "b", 0), Album.new(2, "b", "a", 0)]
      Library.list.first.name.should == "a"
    end
  end
  
  describe "next" do
    before do
      Library.class_eval do
        @next = []
      end
    end
    
    it "should provide read and add methods for 'next'" do
      Library.should respond_to(:next)
      Library.should respond_to(:<<)
    end
    
    it "should add an album to the next list when '<<' is called" do
      album = Album.new(1, "a", "a", 0)
      Library << album
      Library.next.should include(album)
    end
    
    it "should sort the list by number of votes" do
      Library << album1 = Album.new(1, "a", "a", 0)
      Library << album2 = Album.new(2, "a", "b", 1)
      Library.next.should == [album2, album1]
    end
  end
  
  describe "play next" do
    before do
      Library.class_eval do
        @next = [Album.new(1, "artist", "my album", 0)]
      end
      Library.stub! :clear
      Library.stub! :current_song_callback
      
      @song1 = MPD::Song.new
      { "artist" => "me1", "title" => "song1", "album" => "hits1", "track" => "2", "file" => "file1" }.each { |k, v| @song1[k] = v }
      @song2 = MPD::Song.new
      { "artist" => "me2", "title" => "song2", "album" => "hits2", "track" => "1", "file" => "file2" }.each { |k, v| @song2[k] = v }
      
      MPD.stub!(:new).and_return @mpd =
        mock("MPD", :connect => nil, :register_callback => nil, :albums => [], :current_song => nil, :clear => nil, :add => nil, :play => true)
      @mpd.stub!(:find).and_return @new_songs = [@song1, @song2]
      
      Library.setup
    end
    
    it "should do nothing if we dont have a next album in the list" do
      Library.class_eval do
        @next = []
      end
      @mpd.should_not_receive :clear
      
      Library.play_next
    end
    
    it "should remove the album from the list" do
      Library.play_next
      Library.next.should be_empty
    end
    
    it "should clear the playlist if we have a album in the list" do
      @mpd.should_receive :clear
      Library.play_next
    end
    
    it "should look for all songs matching the album exactly" do
      @mpd.should_receive(:find).with("album", "my album").and_return []
      Library.play_next
    end
    
    it "should order the file list by track number" do
      @new_songs.should_receive(:sort_by).and_return []
      Library.play_next
    end
    
    it "should add all files to the playlist" do
      [@song1, @song2].each { |s| @mpd.should_receive(:add).with s.file }
      Library.play_next
    end
    
    it "should start playback" do
      @mpd.should_receive :play
      Library.play_next
    end
  end
  
  describe "song" do
    before do
      Library.class_eval do
        @song = "some song"
      end
    end
    
    it "should return the value of the variable" do
      Library.song.should == "some song"
    end
  end
  
  describe "current song callback" do
    before do
      Library.class_eval do
        @song = nil
      end
      Library.stub! :play_next
      
      @song = MPD::Song.new
      { "artist" => "me", "title" => "song", "album" => "hits" }.each { |k, v| @song[k] = v }
    end
    
    it "should update the song variable" do
      Library.current_song_callback @song
      Library.song.should == "me - song (hits)"
    end
    
    it "should set it to an empty string if we get nothing" do
      Library.current_song_callback nil
      Library.song.should == ""
    end
    
    it "should load next album if the song is nil (no next song in the playlist) and we are enabled" do
      Library.control :enable
      Library.should_receive :play_next
      Library.current_song_callback nil
    end
    
    it "should not load the next album if we havent enabled to app" do
      Library.control :disable
      Library.should_not_receive :play_next
      Library.current_song_callback nil
    end
  end
  
  describe "control" do
    before do
      MPD.stub!(:new).and_return @mpd =
        mock("MPD", :connect => nil, :register_callback => nil, :albums => [], :current_song => nil)
      Library.setup
      
      @mpd.stub! :action
    end
    
    it "should execute the given action on the mpd object" do
      @mpd.should_receive :action
      Library.control :action
    end
    
    it "should set the enabled variable to true if we call the method with 'enable'" do
      Library.control :enable
      Library.should be_enabled
    end
    
    it "should not load a new album if we are currently playing a song" do
      Library.class_eval do
        @song = "some song"
      end
      
      Library.should_not_receive :play_next
      Library.control :enable
    end
    
    it "should load a new album if we are not playing anything right now" do
      Library.class_eval do
        @song = ""
      end
      
      Library.should_receive :play_next
      Library.control :enable
    end
    
    it "should set the enabled variable to false if we call the method with 'disable'" do
      Library.control :enable; Library.control :disable
      Library.should_not be_enabled
    end
  end
  
  describe "search" do
    before do
      MPD.stub!(:new).and_return @mpd =
        mock("MPD", :connect => nil, :register_callback => nil, :albums => [], :current_song => nil, :search => [])
      Library.setup
      
      Library.stub!(:list).and_return @list = [Album.new(1, "artist", "hits", 0)]
      
      @song = MPD::Song.new
      { "artist" => "me", "title" => "song", "album" => "hits" }.each { |k, v| @song[k] = v }
    end
    
    it "should return the complete list if we have a nil query" do
      Library.search(nil).should == @list
    end
    
    it "should return the complete list if we have a blank query" do
      Library.search("").should == @list
    end
    
    it "should return the complete list if we get an error" do
      @mpd.stub!(:search).and_raise RuntimeError.new
      Library.search("query").should == @list
    end
    
    it "should use the MPD server to search for matches in title, artist and album" do
      @mpd.should_receive(:search).with("artist", "query").and_return []
      @mpd.should_receive(:search).with("album", "query").and_return []
      @mpd.should_receive(:search).with("title", "query").and_return []
      
      Library.search "query"
    end
    
    it "should return an empty array if we cant find anything" do
      Library.search("query").should be_empty
    end
    
    it "should return an empty array if we found something but dont have a (matching) album in the list" do
      Library.stub!(:list).and_return []
      @mpd.should_receive(:search).with("album", "query").and_return [@song]
      
      Library.search("query").should be_empty
    end
    
    it "should match the found songs against the album list and return the matches" do
      @mpd.should_receive(:search).with("album", "query").and_return [@song]
      Library.search("query").should == @list
    end
    
    it "should return every matched album only once" do
      @mpd.stub!(:search).and_return [@song]
      Library.search("query").should == @list
    end
  end
end

describe Album do
  
  describe "vote" do
    before do
      @album = Album.new(1, "artist", "album", 0)
    end
    
    [0, 1, -1, 4, -3].each do |by|
      it "should change the votes by #{by}" do
        @album.vote by, "me"
        @album.votes.should == by
      end
    end
    
    it "should save the second param in the 'voted by' list" do
      @album.vote 1, "me"
      @album.voted_by.should include("me")
    end
    
    it "should not allow a vote, if we have already voted" do
      2.times { @album.vote 1, "me" }
      @album.votes.should == 1
    end
  end
  
  describe "can be voted for by?" do
    before do
      @album = Album.new(1, "artist", "album", 0)
    end
    
    it "should return true if the 'voted by' list doesnt contain the given string" do
      @album.can_be_voted_for_by?("me").should be_true
    end
    
    it "should return false if the string is in the 'voted by' list" do
      @album.vote 1, "me"
      @album.can_be_voted_for_by?("me").should be_false
    end
  end
  
  describe "to hash" do
    before do
      @album = Album.new(1, "artist", "album", 0)
    end
    
    it "should map all attributes into a hash" do
      @album.to_hash("me").should == { :id => 1, :artist => "artist", :name => "album", :votes => 0, :votable => true }
    end
    
    it "should have a negative votable value if this user cant vote" do
      @album.stub!(:can_be_voted_for_by?).and_return false
      @album.to_hash("me")[:votable].should be_false
    end
  end
end