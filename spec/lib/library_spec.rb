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
    
    it "should grab the list of albums from the MPD instance" do
      @mpd.should_receive(:albums).and_return ["first", "second"]
      Library.setup
      
      Library.list.size.should == 2
    end
    
    it "should get the currently played song from the server" do
      @mpd.should_receive(:current_song).and_return nil
      Library.setup
      
      Library.song.should == ""
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
      Library.list = [Album.new(1, "b", 0), Album.new(2, "a", 0)]
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
      album = Album.new(1, "a", 0)
      Library << album
      Library.next.should include(album)
    end
    
    it "should sort the list by number of votes" do
      Library << album1 = Album.new(1, "a", 0)
      Library << album2 = Album.new(2, "b", 1)
      Library.next.should == [album2, album1]
    end
  end
  
  describe "play next" do
    before do
      Library.class_eval do
        @next = [Album.new(1, "my album", 0)]
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
    
    it "should load next album if the song is nil (no next song in the playlist)" do
      Library.should_receive :play_next
      Library.current_song_callback nil
    end
  end
end

describe Album do
  
  describe "vote" do
    before do
      @album = Album.new(1, "album", 0)
    end
    
    [0, 1, -1, 4, -3].each do |by|
      it "should change the votes by #{by}" do
        @album.vote by
        @album.votes.should == by
      end
    end
  end
end