require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe MpdConnection do

  describe "setup" do
    before do
      MpdConnection.class_eval do
        @mpd = nil
      end
      
      MPD.stub!(:new).and_return @mpd = mock("MPD", :connect => nil, :register_callback => nil)
      Library.stub! :current_song_callback
      Library.stub! :playlist_callback
      Library.stub! :volume_callback
    end
    
    it "should get a new connection to the MPD server with the specified parameters" do
      MPD.should_receive(:new).with("mpd server", 1234).and_return @mpd
      @mpd.should_receive(:connect).with false
      
      MpdConnection.setup "mpd server", 1234
    end
    
    it "should connect to the server using callbacks when the callbacks arg is true" do
      @mpd.should_receive(:connect).with true
      MpdConnection.setup "mpd server", 1234, true
    end
    
    it "should register a callback for the 'current song'" do
      @mpd.should_receive(:register_callback).with Library.method(:current_song_callback), MPD::CURRENT_SONG_CALLBACK
      MpdConnection.setup "server", 1234
    end
    
    it "should register a callback for the 'playlist'" do
      @mpd.should_receive(:register_callback).with Library.method(:playlist_callback), MPD::PLAYLIST_CALLBACK
      MpdConnection.setup "server", 1234
    end
    
    it "should register a callback for the 'volume'" do
      @mpd.should_receive(:register_callback).with Library.method(:volume_callback), MPD::VOLUME_CALLBACK
      MpdConnection.setup "server", 1234
    end
  end
  
  describe "execute" do
    before do
      MPD.stub!(:new).and_return @mpd = mock("MPD", :connect => nil, :register_callback => nil)
      MpdConnection.setup "server", 1234
      
      @mpd.stub! :action
    end
    
    it "should execute the given action on the mpd object" do
      @mpd.should_receive :action
      MpdConnection.execute :action
    end
    
    it "should return the result of the MPD method call" do
      @mpd.stub!(:action).and_return "result!"
      MpdConnection.execute(:action).should == "result!"
    end
  end
  
  describe "volume =" do
    before do
      MPD.stub!(:new).and_return @mpd = mock("MPD", :connect => nil, :register_callback => nil)
      MpdConnection.setup "server", 1234
    end
    
    it "should change the volume on the MPD server" do
      @mpd.should_receive(:volume=).with 41
      MpdConnection.volume = 41
    end
  end
  
  describe "play album" do
    before do
      MPD.stub!(:new).and_return @mpd = mock("MPD", :connect => nil, :register_callback => nil, :clear => nil, :add => nil, :play => nil)
      MpdConnection.setup "server", 1234
      
      @song1 = MPD::Song.new
      { "artist" => "me1", "title" => "song1", "album" => "hits1", "track" => "2", "file" => "file1" }.each { |k, v| @song1[k] = v }
      @song2 = MPD::Song.new
      { "artist" => "me2", "title" => "song2", "album" => "hits2", "track" => "1", "file" => "file2" }.each { |k, v| @song2[k] = v }
      @mpd.stub!(:find).and_return @new_songs = [@song1, @song2]
    end
    
    it "should clear the playlist" do
      @mpd.should_receive :clear
      MpdConnection.play_album "my album"
    end
    
    it "should look for all songs matching the album exactly" do
      @mpd.should_receive(:find).with("album", "my album").and_return []
      MpdConnection.play_album "my album"
    end
    
    it "should order the file list by track number" do
      @new_songs.should_receive(:sort_by).and_return []
      MpdConnection.play_album "my album"
    end
    
    it "should add all files to the playlist" do
      [@song1, @song2].each { |s| @mpd.should_receive(:add).with s.file }
      MpdConnection.play_album "my album"
    end
    
    it "should start playback" do
      @mpd.should_receive :play
      MpdConnection.play_album "my album"
    end
  end
  
  describe "find albums for" do
    before do
      MPD.stub!(:new).and_return @mpd = mock("MPD", :connect => nil, :register_callback => nil, :search => [])
      MpdConnection.setup "server", 1234
      
      @song = MPD::Song.new
      { "artist" => "me", "title" => "song", "album" => "hits" }.each { |k, v| @song[k] = v }
    end
    
    it "should use the MPD server to search for matches in title, artist and album" do
      @mpd.should_receive(:search).with("artist", "query").and_return []
      @mpd.should_receive(:search).with("album", "query").and_return []
      @mpd.should_receive(:search).with("title", "query").and_return []
      
      MpdConnection.find_albums_for("query").should be_empty
    end
    
    it "should return every matched album only once" do
      @mpd.stub!(:search).and_return [@song]
      MpdConnection.find_albums_for("query").should == ["hits"]
    end

    it "should return nothing if we get an error" do
      @mpd.stub!(:search).and_raise RuntimeError.new
      MpdConnection.find_albums_for("query").should be_empty
    end
  end
end