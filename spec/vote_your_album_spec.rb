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

  # it "should get these tests to stop things from failing!"
  describe "GET '/embed'" do
    it "should render the homepage" do
      get "/embed"
      last_response.body.should match(/Vote Your Album!/)
    end
    it 'should use the embed stylesheet' do
      get "/embed"
      last_response.body.should match(/embed.css/)
    end
  end
  
  describe "GET '/list/:type'" do
    before do
      Album.stub!("all").and_return [@album = Album.new(:id => 1, :artist => "artist", :name => "name")]
    end
    
    it "should call the given type on the Album class to get the list" do
      Album.should_receive("some_list").and_return []
      get "/list/some_list"
    end
    
    it "should return the list" do
      get "/list/all"
      last_response.body.should match(%q{<span class='artist'>artist</span>})
      last_response.body.should match(%q{<span class='name'>name</span>})
    end
    
    it "should call the 'value' method on the album(s) if we get one" do
      Album.stub!(:value_method_for).and_return :something
      @album.should_receive :something
      get "/list/all"
    end
  end
  
  describe "GET '/search/:q'" do
    before do
      Album.stub!(:search).and_return [@album = Album.new(:id => 1, :artist => "artist", :name => "name")]
    end
    
    it "should search for matching album using the library" do
      Album.should_receive(:search).with("query").and_return []
      get "/search", :q => "query"
    end
    
    it "should return the list" do
      get "/search", :q => "query"
      last_response.body.should match(%q{<span class='artist'>artist</span>})
      last_response.body.should match(%q{<span class='name'>name</span>})
    end
  end
  
  describe "GET '/upcoming'" do
    before do
      @album = Album.new(:artist => "artist", :name => "name")
      Nomination.stub!(:active).and_return [@nomination = Nomination.new(:id => 1, :album => @album, :score => 2)]
    end
    
    it "should return the list" do
      get "/upcoming"
      last_response.body.should match(%q{<span class='score positive' title='Score: 2'>2</span>})
      last_response.body.should match(%q{<span class='artist'>artist</span>})
      last_response.body.should match(%q{<span class='name'>name</span>})
    end
    
    it "should show the vote buttons if we can vote" do
      get "/upcoming"
      last_response.body.should match(%{a class='up'})
      last_response.body.should match(%{a class='down'})
    end
    
    it "should not show the vote buttons if we cant vote" do
      @nomination.stub!(:can_be_voted_for_by?).and_return false
      
      get "/upcoming"
      last_response.body.should_not match(%{a class='up'})
      last_response.body.should_not match(%{a class='down'})
    end
    
    it "should not have a deleteable class if we arent the 'owner'" do
      get "/upcoming"
      last_response.body.should match(%{li class='album even '})
    end
    
    it "should have a deleteable class if we are the 'owner'" do
      @nomination.nominated_by = "127.0.0.1"
      
      get "/upcoming"
      last_response.body.should match(%{li class='album even deleteable'})
    end
  end
  
  describe "GET '/status'" do    
    it "should return the volume" do
      MpdProxy.stub!(:volume).and_return 32
      
      get "/status"
      last_response.body.should match(/\"volume\":32/)
    end
    
    it "should contain the 'playing' flag" do
      MpdProxy.stub!(:playing?).and_return false
      
      get "/status"
      last_response.body.should match(/\"playing\":false/)
    end
    
    it "should not include the information about the current album if we are not playing anything" do
      MpdProxy.stub!(:playing?).and_return false
      
      get "/status"
      last_response.body.should_not match(/\"current_album\"/)
    end
    
    describe "currently playing an album" do
      before do
        MpdProxy.stub!(:playing?).and_return true
        
        @album = Album.new(:artist => "c", :name =>  "three")
        Nomination.stub!(:current).and_return @nomination = Nomination.new(:album => @album, :force_score => 1)
      end
      
      it "should include the name of the current album" do
        get "/status"
        last_response.body.should match(/\"current_album\":\"c - three\"/)
      end
      
      it "should include the number of necessary (remaining) forces" do
        get "/status"
        last_response.body.should match(/\"force_score\":1/)
      end
      
      it "should include whether we can force" do
        @nomination.stub!(:can_be_forced_by?).and_return false
        
        get "/status"
        last_response.body.should match(/\"forceable\":false/)
      end
    end
  end
  
  describe "POST '/add/:id'" do
    before do
      Album.stub!(:get).and_return @album = Album.new(:id => 123, :artist => "artist", :name =>  "album")
      @album.nominations.stub! :create
      
      Nomination.stub!(:active).and_return [Nomination.new(:album => @album)]
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
    
    it "should return the new list" do
      post "/add/321"
      last_response.body.should match(%q{<span class='score})
    end
  end
  
  { :up => 1, :down => -1 }.each do |action, change|
    describe "POST '/up/:id'" do
      before do
        album = Album.new(:artist => "artist", :name =>  "album")
        Nomination.stub!(:get).and_return @nomination = Nomination.new(:id => 123, :album => album)
        @nomination.stub! :vote
        
        Nomination.stub!(:active).and_return [@nomination]
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
      
      it "should return the new list" do
        post "/#{action}/321"
        last_response.body.should match(%q{<span class='score})
      end
    end
  end
  
  describe "POST '/remove/:id" do
    before do
      album = Album.new(:artist => "artist", :name =>  "album")
      Nomination.stub!(:get).and_return @nomination = Nomination.new(:id => 123, :album => album)
      @nomination.stub! :remove
      
      Nomination.stub!(:active).and_return [@nomination]
    end
    
    it "should remove the Nomination" do
      Nomination.should_receive(:get).with(123).and_return @nomination
      @nomination.should_receive(:remove).with "127.0.0.1"
      post "/remove/123"
    end
  
    it "should do nothing when we can't find the nomination" do
      Nomination.should_receive(:get).with(321).and_return nil
      @nomination.should_not_receive :remove
      post "/remove/321"
    end
    
    it "should return the new list" do
      post "/remove/321"
      last_response.body.should match(%q{<span class='score})
    end
  end
  
  describe "POST force" do
    before do
      Nomination.stub!(:current).and_return @nomination = Nomination.new(:id => 123)
      @nomination.stub! :force
    end
    
    it "should force the next album" do
      @nomination.should_receive(:force).with "127.0.0.1"
      post "/force"
    end
    
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
      Nomination.stub!(:current).and_return Nomination.new
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