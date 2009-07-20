require File.join(File.dirname(__FILE__) + '/spec_helper')

describe "vote your album:" do
  
  before do
    @song = MPD::Song.new
    { "artist" => "me", "title" => "song", "album" => "hits" }.each { |k, v| @song[k] = v }
    MPD.stub!(:new).and_return @mpd = mock('mpd', :connect => true, :current_song => @song, :albums => nil)
    
    Library.stub!(:list).and_return [Album.new(1, "one", 0), Album.new(2, "two", 0)]
    Library.stub!(:next).and_return [Album.new(3, "three", 0)]
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
    
    it "should assign the list of next albums" do
      get "/"
      last_response.body.should match(/three/)
    end
  end
  
  describe "GET '/current_song'" do
    it "should return the current song as text" do
      get "/current_song"
      last_response.body.should == "me - song (hits)"
    end
    
    it "should return an empty string if we dont play anything right now" do
      @mpd.stub!(:current_song).and_return nil
      get "/current_song"
      last_response.body.should == ""
    end
  end
  
  describe "GET '/add/:id'" do
    before do
      Library.stub!(:list).and_return [@album = Album.new(123, "album", 0)]
    end
    
    it "should add the Album to the Library's next list if we know the album" do
      Library.should_receive(:<<).with @album
      get "/add/123"
    end
    
    it "should do nothing when we can't find the album in the list" do
      Library.should_not_receive :<<
      get "/add/321"
    end
  end
end