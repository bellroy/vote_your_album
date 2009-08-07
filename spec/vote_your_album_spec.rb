require File.join(File.dirname(__FILE__) + '/spec_helper')

describe "vote your album:" do
  
  before do
    Library.stub!(:current_song).and_return "me - song (hits)"
  end
  
  describe "GET '/'" do
    before do
      Library.stub!(:list).and_return [Album.new(:artist => "a", :name => "one"), Album.new(:artist => "b", :name => "two")]
      Library.stub!(:upcoming).and_return [VoteableAlbum.new(:artist => "c", :name => "three")]
    end
    
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
  
  describe "GET '/status'" do
    it "should return the current song inside the JSON" do
      get "/status"
      last_response.body.should match(/\"song\":\"me - song \(hits\)\"/)
    end
    
    it "should include the next album list as a sub hash" do
      Library.stub!(:upcoming).and_return [VoteableAlbum.new(:id => 3, :artist => "c", :name =>  "three")]
      get "/status"
      [/\"next\":\[.*\]/, /\"id\":3/, /\"artist\":\"c\"/, /\"name\":\"three\"/, /\"rating\":0/, /\"votable\":true/].each { |re| last_response.body.should match(re) }
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
    before do
      Library.stub!(:upcoming).and_return [@album = VoteableAlbum.new(:id => 123, :artist => "artist", :name =>  "album")]
    end
    
    it "should vote the Album #{action}" do
      @album.should_receive(:vote).with change, "127.0.0.1"
      get "/#{action}/123"
    end
    
    it "should do nothing when we can't find the album in the list" do
      @album.should_not_receive :vote
      get "/add/321"
    end
  end
  
  describe "search" do
    before do
      Library.stub!(:search).and_return []
    end
    
    it "should search for matching album using the library" do
      Library.should_receive(:search).with("query").and_return []
      post "/search", :q => "query"
    end
  end
  
  [:previous, :next].each do |action|
    it "should execute the provided action on the Library class" do
      MpdConnection.should_receive(:execute).with action
      get "/control/#{action}"
    end
  end
end