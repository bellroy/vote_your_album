require File.join(File.dirname(__FILE__) + '/spec_helper')

describe "vote your album:" do
  
  before do
    Library.stub!(:song).and_return "me - song (hits)"
  end
  
  describe "GET '/'" do
    before do
      Library.stub!(:list).and_return [Album.new(1, "a", "one", 0), Album.new(2, "b", "two", 0)]
      Library.stub!(:next).and_return [Album.new(3, "c", "three", 0)]
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
      Library.stub!(:next).and_return [Album.new(3, "c", "three", 0)]
      get "/status"
      [/\"next\":\[.*\]/, /\"id\":3/, /\"artist\":\"c\"/, /\"name\":\"three\"/, /\"votes\":0/, /\"votable\":true/].each { |re| last_response.body.should match(re) }
    end
    
    it "should include the enabled flag" do
      Library.stub!(:enabled?).and_return true
      get "/status"
      last_response.body.should match(/\"enabled\":true/)
    end
  end
  
  describe "GET '/add/:id'" do
    before do
      Library.stub!(:list).and_return [@album = Album.new(123, "artist", "album", 0)]
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
      Library.stub!(:list).and_return [@album = Album.new(123, "artist", "album", 0)]
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
  
  [:enable, :disable, :previous, :next].each do |action|
    it "should execute the provided action on the Library class" do
      Library.should_receive(:control).with action
      get "/control/#{action}"
    end
  end
end