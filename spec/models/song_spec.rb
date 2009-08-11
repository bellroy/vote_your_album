require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Song do
  
  describe "create from mpd" do
    before do
      @library = Library.new
      Song.stub! :create
      
      @mpd_song = MPD::Song.new
      { "track" => "1", "artist" => "me", "title" => "song", "album" => "hits" }.each { |k, v| @mpd_song[k] = v }
      
      @album = Album.new
      Library.stub!(:current).and_return PlayedAlbum.new(:album => @album)
    end
    
    it "should take the respective attributes from the given MPD::Song object" do
      Song.should_receive(:create).with :library => @library, :track => "1", :artist => "me", :title => "song", :album => @album
      Song.create_from_mpd @library, @mpd_song
    end
    
    it "should assign a nil album if we dont have a current album" do
      Library.stub!(:current).and_return nil
      Song.should_receive(:create).with :library => @library, :track => "1", :artist => "me", :title => "song", :album => nil
      Song.create_from_mpd @library, @mpd_song
    end
  end
end