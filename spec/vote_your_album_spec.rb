require File.join(File.dirname(__FILE__) + '/spec_helper')

describe "vote your album:" do

  before do
    Album.stub!(:current).and_return nil
  end

  describe "GET '/'" do
    it "should render the homepage" do
      get "/"
      last_response.body.should match(/Vote Your Album/)
    end
  end

  describe "GET '/music/:type'" do
    before(:all) do
      Struct.new("Album", :id, :artist, :name) do
        def to_hash(user)
          { :id => id, :artist => artist, :name => name }
        end
      end
    end

    before do
      @album = Album.new
      @album.stub! :to_hash => { :id => 1, :artist => "artist", :name => "name" }

      Album.stub!("all").and_return [@album]
    end

    it "should call the given type on the Album class to get the list" do
      Album.should_receive("some_list").and_return []
      get "/music/some_list"
    end

    it "should return the list as a JSON array (of hashes)" do
      get "/music/all"
      last_response.body.should match(/\"id\":1/)
      last_response.body.should match(/\"artist\":\"artist\"/)
      last_response.body.should match(/\"name\":\"name\"/)
    end

    it "should work with Struct's as well" do
      Album.stub!("all").and_return [Struct::Album.new(2, "other", "hits")]
      get "/music/all"
      last_response.body.should match(/\"id\":2/)
      last_response.body.should match(/\"artist\":\"other\"/)
      last_response.body.should match(/\"name\":\"hits\"/)
    end
  end

  describe "GET '/search/:q'" do
    before do
      @album = Album.new
      @album.stub! :to_hash => { :id => 1, :artist => "artist", :name => "name" }

      Album.stub!(:search).and_return [@album]
    end

    it "should search for matching album using the library" do
      Album.should_receive(:search).with("query").and_return []
      get "/search", :q => "query"
    end

    it "should return the list as a JSON array (of hashes)" do
      get "/search", :q => "query"
      last_response.body.should match(/\"id\":1/)
      last_response.body.should match(/\"artist\":\"artist\"/)
      last_response.body.should match(/\"name\":\"name\"/)
    end

    it "should return random albums when submitting 'shuffle'" do
      album = Album.new
      album.stub! :to_hash => { :id => 2 }

      Album.stub! :random => [album]

      get "/search", :q => "shuffle"
      last_response.body.should match(/\"id\":2/)
    end

    it "should load all albums for the given tag if the search starts with 'tag:'" do
      Tag.stub!(:first).with(:name => "rock").and_return tag = Tag.new

      album = Album.new(:id => 3, :artist => "tagged!", :name => "bla")
      album.stub! :to_hash => { :id => 3 }

      tag.stub! :albums => [album]

      get "/search", :q => "tag:rock"
      last_response.body.should match(/\"id\":3/)
    end
  end

  describe "GET '/upcoming'" do
    before do
      @album = Album.new(:artist => "artist", :name => "name")
      Nomination.stub!(:active).and_return [@nomination = Nomination.new(:id => 1, :album => @album, :score => 2)]
    end

    it "should return the list" do
      get "/upcoming"
      last_response.body.should match(%q{<p>artist</p>})
      last_response.body.should match(%q{<p>name</p>})
    end

    it "should show the vote buttons if we can vote" do
      get "/upcoming"
      last_response.body.should match(%{a class='up'})
    end

    it "should not show the vote buttons if we cant vote" do
      @nomination.stub!(:can_be_voted_for_by?).and_return false

      get "/upcoming"
      last_response.body.should_not match(%{a class='up'})
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
        MpdProxy.stub!(:total).and_return 321
        MpdProxy.stub!(:time).and_return 123

        song = MPD::Song.new
        { "artist" => "me", "title" => "song" }.each { |k, v| song[k] = v }
        song.stub!(:to_json).and_return "{\"artist\":\"me\",\"title\":\"song\"}"
        MpdProxy.stub!(:current_song).and_return song

        @album = Album.new(:artist => "c", :name =>  "three")
        Nomination.stub!(:current).and_return @nomination = Nomination.new(:album => @album)
        @nomination.stub! :nominated_by => "blubbi", :id => 123
      end

      it "should include the id of the nomination" do
        get "/status"
        last_response.body.should match(/\"id\":123/)
      end

      it "should include the name of the current album" do
        get "/status"
        last_response.body.should match(/\"current_album\":\"c - three\"/)
      end

      it "should include the information of the current song" do
        get "/status"
        last_response.body.should match(/\"artist\":\"me\"/)
        last_response.body.should match(/\"title\":\"song\"/)
      end

      it "should include the time total for the song" do
        get "/status"
        last_response.body.should match(/\"total\":\"05:21\"/)
      end

      it "should include the time remaining for the song" do
        get "/status"
        last_response.body.should match(/\"time\":\"-02:03\"/)
      end

      it "should include the album nominator" do
        get "/status"
        last_response.body.should match(/\"nominated_by\":\"blubbi\"/)
      end

      it "should include whether we can vote" do
        @nomination.stub!(:can_be_voted_for_by?).and_return false

        get "/status"
        last_response.body.should match(/\"voteable\":false/)
      end
    end
  end

  describe "GET '/songs/:id'" do
    before do
      Album.stub!(:get).and_return @album = Album.new(:id => 123, :artist => "artist", :name =>  "album")
    end

    it "should return an empty result set if the album has no songs" do
      get "/songs/123"
      last_response.body.should == "[]"
    end

    describe "with songs" do
      before do
        @album.stub! :songs => [
          Song.new(:id => 11, :track => "1", :artist => "artist", :title => "title 1", :length => 122),
          Song.new(:id => 12, :track => "2", :artist => "artist", :title => "title 2", :length => 322),
        ]
      end

      it "should return the songs of the album as JSON" do
        get "/songs/123"
        last_response.body.should match(/\"title\":\"title 1\"/)
        last_response.body.should match(/\"title\":\"title 2\"/)
      end

      it "should return the formatted length" do
        get "/songs/123"
        last_response.body.should match(/\"length\":\"02:02\"/)
      end
    end
  end

  describe "POST '/add'" do
    before do
      User.stub! :first => User.new

      Album.stub!(:get).and_return @album = Album.new(:id => 123, :artist => "artist", :name =>  "album")
      @album.stub! :nominate

      Nomination.stub!(:active).and_return [Nomination.new(:album => @album)]

      MpdProxy.stub!(:playing?).and_return true
    end

    it "should nominate the album if we can find one" do
      Album.should_receive(:get).with(123).and_return @album
      @album.should_receive :nominate
      post "/add", :album_id => 123
    end

    it "should do nothing when we can't find the album in the list" do
      Album.should_receive(:get).with(321).and_return nil
      @album.should_not_receive :nominate
      post "/add", :album_id => 321
    end

    it "should pass in the selected songs if present" do
      Album.should_receive(:get).with(123).and_return @album
      @album.should_not_receive(:nominate).with @album, [1, 2, 3]
      post "/add", :album_id => 123, :songs => [1, 2, 3]
    end

    it "should not immediately play the just added album if we already play some music" do
      MpdProxy.should_not_receive :play_next
      post "/add"
    end

    it "should immediately play the just album if we arent playing anything right now" do
      pending
      MpdProxy.stub!(:playing?).and_return false
      MpdProxy.should_receive :play_next

      post "/add", :album_id => 321
    end

    it "should return the new list" do
      post "/add", :album_id => 321
      last_response.body.should match(%q{aside class='voting})
    end
  end

  { :up => 1, :down => -1 }.each do |action, change|
    describe "POST '/up/:id'" do
      before do
        User.stub! :first => @user = User.new

        album = Album.new(:artist => "artist", :name =>  "album")
        Nomination.stub!(:get).and_return @nomination = Nomination.new(:id => 123, :album => album)
        @nomination.stub! :vote

        Nomination.stub!(:active).and_return [@nomination]
      end

      it "should vote the Nomination #{action}" do
        Nomination.should_receive(:get).with(123).and_return @nomination
        @nomination.should_receive(:vote).with change, @user
        post "/#{action}/123"
      end

      it "should do nothing when we can't find the nomination" do
        Nomination.should_receive(:get).with(321).and_return nil
        @nomination.should_not_receive :vote
        post "/#{action}/321"
      end

      it "should return the new list" do
        post "/#{action}/321"
        last_response.body.should match(%q{aside class='voting})
      end
    end
  end

  describe "POST '/remove/:id" do
    before do
      User.stub! :first => User.new

      album = Album.new(:artist => "artist", :name =>  "album")
      Nomination.stub!(:get).and_return @nomination = Nomination.new(:id => 123, :album => album)
      @nomination.stub! :remove

      Nomination.stub!(:active).and_return [@nomination]
    end

    it "should remove the Nomination" do
      Nomination.should_receive(:get).with(123).and_return @nomination
      @nomination.should_receive :remove
      post "/remove/123"
    end

    it "should do nothing when we can't find the nomination" do
      Nomination.should_receive(:get).with(321).and_return nil
      @nomination.should_not_receive :remove
      post "/remove/321"
    end

    it "should return the new list" do
      post "/remove/321"
      last_response.body.should match(%q{aside class='voting})
    end
  end

  [:previous, :stop, :play, :next].each do |action|
    describe "POST '/control/#{action}'" do
      before do
        MpdProxy.stub! :execute
      end

      it "should execute the provided action on the Library class" do
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
end
