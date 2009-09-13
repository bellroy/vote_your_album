require File.join(File.dirname(__FILE__) + '/spec_helper')

describe "vote your album helpers:" do
  
  describe "score class" do
    before do
      @album = Album.new(:artist => "artist", :name => "name")
      Nomination.stub!(:active).and_return [@nomination = Nomination.new(:id => 1, :album => @album, :score => 2)]
    end
    
    it "should return 'positive' if we have a positive score" do
      get "/upcoming"
      last_response.body.should match(%q{<span class='score positive' title='Score: 2'>2</span>})
    end
    
    it "should return 'negative' if we have a negative score" do
      @nomination.score = -2
      get "/upcoming"
      last_response.body.should match(%q{<span class='score negative' title='Score: -2'>-2</span>})
    end
    
    it "should return nothing if we have a score of 0" do
      @nomination.score = 0
      get "/upcoming"
      last_response.body.should match(%q{<span class='score ' title='Score: 0'>0</span>})
    end
  end
  
  describe "album attributes" do
    before do
      @album = Album.new(:artist => "artist", :name => "name")
      Nomination.stub!(:active).and_return [@nomination = Nomination.new(:id => 1, :album => @album, :score => 2)]
    end
    
    it "should have a set of classes by default" do
      get "/upcoming"
      last_response.body.should match(%{li class='album loaded even'})
    end
    
    it "should have a deleteable class if we have nominated the album" do
      @nomination.stub!(:owned_by?).and_return true
      get "/upcoming"
      last_response.body.should match(%{li class='album loaded even deleteable'})
    end
    
    it "should add an expanded class to the album if we had it expanded previously" do
      get "/upcoming?&expanded[]=1"
      last_response.body.should match(%{li class='album loaded even expanded'})
    end
    
    it "should not show a title if we have a positive score" do
      get "/upcoming"
      last_response.body.should_not match(/TTL/)
    end
    
    it "should show the TTL as the title if we have one" do
      @nomination.stub!(:ttl).and_return 123
      get "/upcoming"
      last_response.body.should match(%{TTL: -02:03})
    end
  end
  
  describe "to time" do
    before do
      MpdProxy.stub!(:playing?).and_return true
      Nomination.stub!(:current).and_return @nomination = Nomination.new
    end
    
    { 0 => "-00:00", 1 => "-00:01", 60 => "-01:00", 123 => "-02:03", 3599 => "-59:59",
      3600 => "-01:00:00", 3661 => "-01:01:01", 7199 => "-01:59:59" }.each do |seconds, time|
      it "should return the formatted value of the saved remaining seconds: #{seconds}" do
        MpdProxy.stub!(:time).and_return seconds
        post "/play"
        last_response.body.should match(/\"time\":\"#{time}\"/)
      end
    end
  end
end