require File.join(File.dirname(__FILE__) + '/spec_helper')

describe "vote your album:" do
  
  before do
    @song = MPD::Song.new
    { "artist" => "me", "title" => "song", "album" => "hits" }.each { |k, v| @song[k] = v }
    @albums = %w[one two]
    
    @mpd = MPD.stub!(:new).and_return @mpd = mock('mpd', :connect => true, :current_song => @song, :albums => @albums)
  end
  
  describe "GET '/'" do
    it "should render the homepage" do
      get "/"
      last_response.body.should match(/Currently Playing/)
    end
    
    it "should asssign the current song to an instance variable" do
      get "/"
      last_response.body.should match(/me - song \(hits\)/)
    end
    
    it "should assign the complete list of available albums" do
      get "/"
      last_response.body.should match(/one/)
      last_response.body.should match(/two/)
    end
  end
  
  describe "GET '/current_song'" do
    it "should return the current song as text" do
      get "/current_song"
      last_response.body.should == "me - song (hits)"
    end
  end
end