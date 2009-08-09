require File.join(File.dirname(__FILE__) + '/spec_helper')

describe "vote your album:" do
  
  describe "GET '/'" do
    before do
      album = Album.new(:artist => "0", :name => "current")
      Library.stub!(:current).and_return PlayedAlbum.new(:album => album)
      
      Library.stub!(:list).and_return [Album.new(:artist => "a", :name => "one"), Album.new(:artist => "b", :name => "two")]
      
      album = Album.new(:artist => "c", :name => "three")
      Library.stub!(:upcoming).and_return [VoteableAlbum.new(:album => album)]
    end
    
    it "should render the homepage" do
      get "/"
      last_response.body.should match(/Vote Your Album!/)
    end
    
    it "should display the currently played album" do
      get "/"
      last_response.body.should match(/0 - current/)
    end
    
    it "should display the complete list of available albums" do
      get "/"
      last_response.body.should match(/one/)
      last_response.body.should match(/two/)
    end
    
    it "should display the list of next albums" do
      get "/"
      last_response.body.should match(/three/)
    end
  end
  
  describe "GET '/status'" do
    before do
      @album = Album.new(:artist => "c", :name =>  "three")
    end
    
    it "should return the currently played album" do
      Library.stub!(:current).and_return PlayedAlbum.new(:album => @album)
      
      get "/status"
      [/\"current\":\{.*\}/, /\"artist\":\"c\"/, /\"name\":\"three\"/, /\"remaining\":3/, /\"voteable\":true/].each { |re| last_response.body.should match(re) }
    end
    
    it "should include the next album list as a sub hash" do
      Library.stub!(:upcoming).and_return [VoteableAlbum.new(:id => 3, :album => @album)]
      
      get "/status"
      [/\"upcoming\":\[.*\]/, /\"id\":3/, /\"artist\":\"c\"/, /\"name\":\"three\"/, /\"rating\":0/, /\"voteable\":true/].each { |re| last_response.body.should match(re) }
    end
  end
  
  describe "GET '/add/:id'" do
    before do
      Library.stub!(:list).and_return [@album = Album.new(:id => 123, :artist => "artist", :name =>  "album")]
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
  
  { :up => 1, :down => -1 }.each do |action, change|
    describe "GET '/up/:id'" do
      before do
        album = Album.new(:artist => "artist", :name =>  "album")
        Library.stub!(:upcoming).and_return [@v_album = VoteableAlbum.new(:id => 123, :album => album)]
      end
    
      it "should vote the Album #{action}" do
        @v_album.should_receive(:vote).with change, "127.0.0.1"
        get "/#{action}/123"
      end
    
      it "should do nothing when we can't find the album in the list" do
        @v_album.should_not_receive :vote
        get "/add/321"
      end
    end
  end
  
  describe "GET force" do
    it "should force the next album" do
      Library.should_receive(:force).with "127.0.0.1"
      get "/force"
    end
  end
  
  describe "POST '/search/:q'" do
    before do
      Library.stub!(:search).and_return []
    end
    
    it "should search for matching album using the library" do
      Library.should_receive(:search).with("query").and_return []
      post "/search", :q => "query"
    end
  end
  
  [:previous, :stop, :play, :next].each do |action|
    it "should execute the provided action on the Library class" do
      MpdConnection.should_receive(:execute).with action
      get "/control/#{action}"
    end
  end
  
  describe "GET '/play'" do
    before do
      Library.stub! :play_next
      Library.stub!(:playing?).and_return false
    end
    
    it "should play the next album" do
      Library.should_receive :play_next
      get "/play"
    end
    
    it "should not play the next album if we are currently playing something" do
      Library.stub!(:playing?).and_return true
      Library.should_not_receive :play_next
      get "/play"
    end
  end
end