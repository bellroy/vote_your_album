require File.join(File.dirname(__FILE__) + '/spec_helper')

describe "vote your album helpers:" do

  describe "album attributes" do
    before do
      @album = Album.new(:artist => "artist", :name => "name")
      Nomination.stub!(:active).and_return [@nomination = Nomination.new(:id => 1, :album => @album, :score => 0)]
    end

    it "should have a set of classes by default" do
      get "/upcoming"
      last_response.body.should match(%{article class='album'})
    end

    it "should have a deleteable class if we have nominated the album" do
      @nomination.stub!(:owned_by?).and_return true
      get "/upcoming"
      last_response.body.should match(%{article class='album deleteable'})
    end

    it "should have not have a '*-score' class if the score is 0" do
      get "/upcoming"
      last_response.body.should match(%{article class='album'})
    end

    it "should have a 'positive-score' class if the score is > 0" do
      @nomination.stub! :score => 1
      get "/upcoming"
      last_response.body.should match(%{article class='album positive-score'})
    end

    it "should have a 'negative-score' class if the score is < 0" do
      @nomination.stub! :score => -1
      get "/upcoming"
      last_response.body.should match(%{article class='album negative-score'})
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
        get "/status"
        last_response.body.should match(/\"time\":\"#{time}\"/)
      end
    end

    it "should not add a minus at the start if we don't want one" do
      MpdProxy.stub! :total => 123
      get "/status"
      last_response.body.should match(/\"total\":\"02:03\"/)
    end
  end
end