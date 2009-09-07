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
  
  describe "album class" do
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
  end
end