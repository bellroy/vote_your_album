require File.join(File.dirname(__FILE__) + '/spec_helper')

describe "vote your album:" do
  
  before do
    Album.stub!(:current).and_return nil
  end
  
  describe "GET '/'" do
    it "should render the homepage" do
      get "/"
      last_response.body.should match(/Vote Your Album!/)
    end
  end
  
  describe "GET '/list'" do
    before do
      Album.stub!(:all).and_return [@album = Album.new(:id => 1, :artist => "name")]
    end
    
    it "should return the list as a JSON list" do
      get "/list"
      last_response.body.should == [@album.to_hash].to_json
    end
  end
  
  describe "GET '/search/:q'" do
    before do
      Album.stub!(:search).and_return [@album = Album.new(:id => 1, :artist => "name")]
    end
    
    it "should search for matching album using the library" do
      Album.should_receive(:search).with("query").and_return []
      get "/search", :q => "query"
    end
    
    it "should return the list as a JSON list" do
      get "/search", :q => "query"
      last_response.body.should == [@album.to_hash].to_json
    end
  end
  
  describe "GET '/status'" do
    before do
      @album = Album.new(:artist => "c", :name =>  "three")
    end
    
    it "should return the currently played album" do
      Album.stub!(:current).and_return @album
      
      get "/status"
      [/\"current\":\{.*\}/, /\"artist\":\"c\"/, /\"name\":\"three\"/].each { |re| last_response.body.should match(re) }
    end
    
    it "should include the next album list as a sub hash" do
      Nomination.stub!(:all).and_return [Nomination.new(:id => 3, :album => @album)]
      
      get "/status"
      [/\"upcoming\":\[.*\]/, /\"id\":3/, /\"artist\":\"c\"/, /\"name\":\"three\"/, /\"score\":0/, /\"voteable\":true/].each { |re| last_response.body.should match(re) }
    end
    
    it "should return the volume" do
      MpdProxy.stub!(:volume).and_return 32
      
      get "/status"
      last_response.body.should match(/\"volume\":32/)
    end
  end
  
  describe "POST '/add/:id'" do
    before do
      Album.stub!(:get).and_return @album = Album.new(:id => 123, :artist => "artist", :name =>  "album")
      @album.nominations.stub! :create
    end
    
    it "should add the Album to the Library's next list if we know the album" do
      Time.stub!(:now).and_return time = mock("Now", :tv_sec => 1)
      Album.should_receive(:get).with(123).and_return @album
      
      @album.nominations.should_receive(:create).with :status => "active", :created_at => time, :nominated_by => "127.0.0.1"
      post "/add/123"
    end
    
    it "should do nothing when we can't find the album in the list" do
      Album.should_receive(:get).with(321).and_return nil
      Nomination.should_not_receive :create
      post "/add/321"
    end
    
    it "should return the json status response" do
      post "/add/321"
      last_response.body.should match(/\"volume\":/)
    end
  end
  
  { :up => 1, :down => -1 }.each do |action, change|
    describe "POST '/up/:id'" do
      before do
        album = Album.new(:artist => "artist", :name =>  "album")
        Nomination.stub!(:get).and_return @nomination = Nomination.new(:id => 123, :album => album)
        @nomination.stub! :vote
      end
    
      it "should vote the Nomination #{action}" do
        Nomination.should_receive(:get).with(123).and_return @nomination
        @nomination.should_receive(:vote).with change, "127.0.0.1"
        post "/#{action}/123"
      end
    
      it "should do nothing when we can't find the nomination" do
        Nomination.should_receive(:get).with(321).and_return nil
        @nomination.should_not_receive :vote
        post "/#{action}/321"
      end
      
      it "should return the json status response" do
        post "/#{action}/321"
        last_response.body.should match(/\"volume\":/)
      end
    end
  end
  
  describe "POST force" do
    # before do
    #   Library.stub! :force
    # end
    # 
    # it "should force the next album" do
    #   Library.should_receive(:force).with "127.0.0.1"
    #   post "/force"
    # end
    
    it "should return the json status response" do
      post "/force"
      last_response.body.should match(/\"volume\":/)
    end
  end
  
  [:previous, :stop, :play, :next].each do |action|
    describe "POST '/control/#{action}'" do
      before do
        MpdProxy.stub! :execute
      end
      
      it " should execute the provided action on the Library class" do
        MpdProxy.should_receive(:execute).with action
        post "/control/#{action}"
      end
      
      it "should return the json status response" do
        post "/control/#{action}"
        last_response.body.should match(/\"volume\":/)
      end
    end
  end
  
  describe "POST '/volume/:value" do
    before do
      MpdProxy.stub! :change_volume_to
    end
    
    it "should change the volume on the MPD server" do
      MpdProxy.should_receive(:change_volume_to).with 23
      post "/volume/23"
    end
    
    it "should render an empty response body and a status of 200" do
      post "/volume/41"
      last_response.body.should == ""
      last_response.status.should == 200
    end
  end
  
  describe "POST '/play'" do
    before do
      MpdProxy.stub! :play_next
      MpdProxy.stub!(:playing?).and_return false
    end
    
    it "should play the next album" do
      MpdProxy.should_receive :play_next
      post "/play"
    end
    
    it "should not play the next album if we are currently playing something" do
      MpdProxy.stub!(:playing?).and_return true
      MpdProxy.should_not_receive :play_next
      post "/play"
    end
    
    it "should return the json status response" do
      post "/play"
      last_response.body.should match(/\"volume\":/)
    end
  end
end