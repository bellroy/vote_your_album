require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe MpdProxy do

  describe "setup" do
    before do
      MpdProxy.class_eval do
        @mpd = nil
      end
      
      MPD.stub!(:new).and_return @mpd = mock("MPD", :connect => nil, :register_callback => nil)
      MpdProxy.stub! :current_song=
      MpdProxy.stub! :volume=
    end
    
    it "should get a new connection to the MPD server with the specified parameters" do
      MPD.should_receive(:new).with("mpd server", 1234).and_return @mpd
      @mpd.should_receive(:connect).with false
      
      MpdProxy.setup "mpd server", 1234
    end
    
    it "should connect to the server using callbacks when the callbacks arg is true" do
      @mpd.should_receive(:connect).with true
      MpdProxy.setup "mpd server", 1234, true
    end
    
    it "should register a callback for the 'current song'" do
      @mpd.should_receive(:register_callback).with MpdProxy.method(:current_song=), MPD::CURRENT_SONG_CALLBACK
      MpdProxy.setup "server", 1234
    end
    
    it "should register a callback for the 'volume'" do
      @mpd.should_receive(:register_callback).with MpdProxy.method(:volume=), MPD::VOLUME_CALLBACK
      MpdProxy.setup "server", 1234
    end
  end
  
  describe "execute" do
    before do
      MPD.stub!(:new).and_return @mpd = mock("MPD", :connect => nil, :register_callback => nil)
      MpdProxy.setup "server", 1234
      
      @mpd.stub! :action
    end
    
    it "should execute the given action on the mpd object" do
      @mpd.should_receive :action
      MpdProxy.execute :action
    end
    
    it "should return the result of the MPD method call" do
      @mpd.stub!(:action).and_return "result!"
      MpdProxy.execute(:action).should == "result!"
    end
  end
  
  describe "volume accessor" do
    it "should return the volume of the class variable" do
      MpdProxy.class_eval do
        @volume = 41
      end
      
      MpdProxy.volume.should == 41
    end
    
    it "should update the volume variable of the class" do
      MpdProxy.volume = 53
      MpdProxy.volume.should == 53
    end
  end
  
  describe "change volume to" do
    before do
      MPD.stub!(:new).and_return @mpd = mock("MPD", :connect => nil, :register_callback => nil)
      MpdProxy.setup "server", 1234
    end
    
    it "should change the volume on the MPD server" do
      @mpd.should_receive(:volume=).with 41
      MpdProxy.change_volume_to 41
    end
  end
  
  describe "current song accessor" do
    before do
      MpdProxy.stub! :play_next
    end
    
    it "should return the volume of the class variable" do
      MpdProxy.class_eval do
        @current_song = "song"
      end
      
      MpdProxy.current_song.should == "song"
    end
    
    it "should return false for 'playing?' if we dont have a current song" do
      MpdProxy.class_eval do
        @current_song = nil
      end
      
      MpdProxy.should_not be_playing
    end
    
    it "should return true for 'playing?' if we have a current song" do
      MpdProxy.class_eval do
        @current_song = "song"
      end
      
      MpdProxy.should be_playing
    end
    
    it "should assign the song in the param" do
      MpdProxy.current_song = "artist - title"
      MpdProxy.current_song.should == "artist - title"
    end
    
    it "should not play the next album if we get something other than nil" do
      MpdProxy.should_not_receive :play_next
      MpdProxy.current_song = "something"
    end
    
    it "should play the next album if we get nil" do
      MpdProxy.should_receive :play_next
      MpdProxy.current_song = nil
    end
  end
  
  describe "play next" do
    before do
      MPD.stub!(:new).and_return @mpd = mock("MPD", :connect => nil, :register_callback => nil)
      MpdProxy.setup "server", 1234
      
      @mpd.stub! :clear
      @mpd.stub! :add
      @mpd.stub! :play
      
      @album = Album.new(:name => "my name")
      @album.stub!(:update_attributes).and_return true
      
      @next = Nomination.new(:album => @album, :created_at => Time.now)
      @next.stub! :update_attributes
      Nomination.stub!(:active).and_return [@next]
    end
    
    it "should do nothing if we dont have an upcoming album" do
      Nomination.stub!(:active).and_return []
      @album.should_not_receive :update_attributes
      MpdProxy.play_next
    end
    
    it "should clear the playlist before we add the new stuff" do
      @mpd.should_receive :clear
      MpdProxy.play_next
    end
    
    it "should update the status of the nomination to 'played'" do
      Time.stub!(:now).and_return "time"
      @next.should_receive(:update_attributes).with :status => "played", :played_at => "time"
      MpdProxy.play_next
    end
    
    it "should add all songs of the album" do
      @album.stub!(:songs).and_return [song = Song.new(:file => "path")]
      @mpd.should_receive(:add).with "path"
      MpdProxy.play_next
    end
    
    it "should start playback" do
      @mpd.should_receive :play
      MpdProxy.play_next
    end
  end
end