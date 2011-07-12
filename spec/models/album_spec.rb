require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Album do

  describe "played?" do
    before do
      @album = Album.new(:id => 1)
    end

    it "should return false if we dont have any 'played' nominations" do
      @album.should_not be_played
    end

    it "should return true if we have at least one nomination" do
      @album.stub_chain(:nominations, :played).and_return [Nomination.new]
      @album.should be_played
    end
  end

  describe "nominated?" do
    before do
      @album = Album.new(:id => 1)
    end

    it "should return false if we dont have any nominations" do
      @album.should_not be_nominated
    end

    it "should return true if we have at least one nomination" do
      @album.stub!(:nominations).and_return [Nomination.new]
      @album.should be_nominated
    end
  end

  describe "currently nominated?" do
    before do
      @album = Album.new(:id => 1)
    end

    it "should return false if we dont have any nominations" do
      @album.should_not be_currently_nominated
    end

    it "should return true if we have a active nomination" do
      @album.stub!(:active_nominations).and_return [Nomination.new]
      @album.should be_currently_nominated
    end
  end

  describe "nominate" do
    before do
      @user = User.new

      @album = Album.new
      @album.stub!(:songs).and_return []

      @album.nominations.stub!(:create).and_return @nomination = Nomination.new
      @nomination.stub! :vote
      @nomination.stub! :save

      Update.stub! :log
    end

    it "should not nominate the album, if we already have a active nomination" do
      @album.stub!(:currently_nominated?).and_return true
      @album.nominations.should_not_receive :create

      @album.nominate @user, nil
    end

    it "should create a nomination for that album" do
      time = Time.now
      Time.stub!(:now).and_return time

      @album.nominations.should_receive(:create).with(
        :status     => "active",
        :created_at => time,
        :user       => @user,
        :expires_at => (time + Nomination::TTL)
      )
      @album.nominate @user, nil
    end

    it "should also add a up vote immediately for the given user" do
      @nomination.should_receive(:vote).with 1, @user
      @album.nominate @user, nil
    end

    it "should add all songs of the album to the nomination (given we don't provide a list of songs)" do
      @album.stub!(:songs).and_return [song = Song.new(:track => 1)]
      @album.nominate @user, nil
      @nomination.songs.should include(song)
    end

    describe "given a list of songs is provided" do
      before do
        @album.stub!(:songs).and_return [
          @song1 = Song.new(:id => 1),
          @song2 = Song.new(:id => 2),
        ]
      end

      it "should only add the songs provided to the nomination" do
        @album.nominate @user, [2]

        @nomination.songs.should include(@song2)
        @nomination.songs.should_not include(@song1)
      end

      it "should only also work with a list of strings" do
        @album.nominate @user, ["1"]

        @nomination.songs.should include(@song1)
        @nomination.songs.should_not include(@song2)
      end
    end

    it "should save the nomination again, to persist the songs" do
      @nomination.should_receive :save
      @album.nominate @user, nil
    end
  end

  describe "find similar" do
    before do
      @album = Album.new(:id => 123)
      @album.stub_chain(:similar_albums, :all).and_return [Album.new(:id => 1), Album.new(:id => 2)]
    end

    it "should return nil if we can't find a similar album in the DB" do
      @album.stub_chain(:similar_albums, :all).and_return []
      @album.find_similar.should be_nil
    end

    it "should return a random album of a similar artist" do
      @album.find_similar.should be_a(Album)
    end
  end

  describe "to s" do
    before do
      @album = Album.new(:id => 123, :artist => "artist", :name => "album")
    end

    it "should return the artist and name in a string" do
      @album.to_s.should == "artist - album"
    end
  end

  describe "to hash" do
    before do
      @user = mock("User", :has_favourite? => true)
      @album = Album.new(:id => 123, :artist => "artist", :name => "album", :art => "some_url")
    end

    it "should return the album's attributes in a hash" do
      @album.to_hash(@user).should == { :id => 123, :artist => "artist", :name => "album", :art => "some_url", :tags => [], :favourite => true }
    end
  end

  describe "nominate similar" do
    before do
      @current = Album.new(:id => 123)

      @album = Album.new
      @current.stub! :find_similar => @album
      Album.stub! :single_random => @album

      @nomination = Nomination.new
      @album.nominations.stub! :new => @nomination
      @nomination.stub! :save => true

      @songs = [Song.new(:file => "path1"), Song.new(:file => "path2"), Song.new(:file => "path3"), Song.new(:file => "path4")]
      @album.stub!(:songs).and_return @songs
    end

    it "should try to find a similar album" do
      @current.should_receive(:find_similar).and_return @album
      Album.should_not_receive(:get).and_return @album
      Album.nominate_similar @current, 1
    end

    it "should find a random album, if we can't find a similar album" do
      @current.stub! :find_similar => nil
      Album.should_receive(:single_random).and_return @album
      Album.nominate_similar @current, 1
    end

    it "should create a new nomination (that will work as the 'current' one)" do
      @album.nominations.should_receive(:new).with(hash_including(:user_id => 0))
      Album.nominate_similar @current, 1
    end

    it "should assign the songs to the nomination and save it" do
      Album.nominate_similar @current, 5
      @nomination.songs.should == @songs
    end

    it "should add random_tracks x tracks of the album to the playlist" do
      Album.nominate_similar @current, 2
      @nomination.should have(2).songs
    end

    it "should return the nomination if it was created" do
      Album.nominate_similar(@current, 1).should == @nomination
    end

    it "should return false if the nomination couldn't be saved" do
      @nomination.stub! :save => false
      Album.nominate_similar(@current, 1).should be_false
    end
  end

  describe "update" do
    before do
      @song = MPD::Song.new
      {
        "track" => "1",
        "artist" => "me",
        "title" => "song",
        "album" => "album1",
        "time" => "123",
        "file" => "path"
      }.each { |k, v| @song[k] = v }

      Library.stub!(:album_paths).and_return ["abc/album1"]
      MpdProxy.stub!(:songs_for).and_return @songs = [@song]

      Album.stub! :first

      @album = Album.new
      Album.stub!(:new).and_return @album
      @album.stub! :save => true, :fetch_album_art => true, :fetch_tags => true, :fetch_similar => true
      @album.songs.stub!(:first).and_return @song
    end

    it "should fetch all albums from the server" do
      Library.should_receive(:album_paths).and_return []
      Album.update
    end

    it "should not do anything if we already have that album in the DB" do
      Album.should_receive(:first).with(:base_path => "abc/album1").and_return "exists!"
      Album.should_not_receive :build
      Album.update
    end

    it "should build a new album if we dont know it yet" do
      Album.should_receive(:new).with(hash_including(:name => "album1")).and_return @album
      Album.update
    end

    it "should not build an album, if we can't find any songs" do
      MpdProxy.stub!(:songs_for).and_return []
      Album.should_not_receive :new
      Album.update
    end

    it "should add the found songs to the album" do
      @album.songs.should_receive(:new).with :track => 1, :artist => "me", :title => "song", :length => 123, :file => "path"
      Album.update
    end

    ["5", "5/11", "5 of 11"].each do |track|
      it "should convert the track '#{track}' to a integer value" do
        @song["track"] = track
        @album.songs.should_receive(:new).with hash_including(:track => 5)
        Album.update
      end
    end

    it "should get the name of the artist for the album from the songs" do
      @album.should_receive(:artist=).with "me"
      Album.update
    end

    it "should assign a 'Unknown instead of a nil value if we dont have any artists" do
      @song["artist"] = nil
      @album.should_receive(:artist=).with "Unknown"
      Album.update
    end

    it "should take the name of the shortest artist if at least 50% of the song's artist start with the string" do
      @song["artist"] = "longer"
      song2 = MPD::Song.new
      { "track" => 2, "artist" => "MJ", "title" => "song 2", "album" => "album1", "file" => "other" }.each { |k, v| song2[k] = v }
      song3 = MPD::Song.new
      { "track" => 3, "artist" => "MJ & DJ", "title" => "song 3", "album" => "album1", "file" => "other" }.each { |k, v| song3[k] = v }
      MpdProxy.stub!(:songs_for).and_return [@song, song2, song3]

      @album.should_receive(:artist=).with "MJ"
      Album.update
    end

    it "should assign a 'Various Artists' string if we have to many different artists" do
      song2 = MPD::Song.new
      { "track" => 2, "artist" => "MJ", "title" => "song 2", "album" => "album1", "file" => "other" }.each { |k, v| song2[k] = v }
      song3 = MPD::Song.new
      { "track" => 3, "artist" => "lala", "title" => "song 3", "album" => "album1", "file" => "other" }.each { |k, v| song3[k] = v }
      MpdProxy.stub!(:songs_for).and_return [@song, song2, song3]

      @album.should_receive(:artist=).with "Various Artists"
      Album.update
    end

    it "should use the name of the most common name, even if it's not the shortest" do
      @song["artist"] = "Method Man"
      song2 = MPD::Song.new
      { "track" => 2, "artist" => "Method Man", "title" => "song 2", "album" => "album1", "file" => "other" }.each { |k, v| song2[k] = v }
      song3 = MPD::Song.new
      { "track" => 3, "artist" => "Saukrates", "title" => "song 3", "album" => "album1", "file" => "other" }.each { |k, v| song3[k] = v }
      MpdProxy.stub!(:songs_for).and_return [@song, song2, song3]

      @album.should_receive(:artist=).with "Method Man"
      Album.update
    end

    it "should save the new album" do
      @album.should_receive :save
      Album.update
    end
  end

  describe "search" do
    before do
      Album.stub!(:all).and_return @list = ["one", "two"]
    end

    it "should return the complete list if we have a nil query" do
      Album.search(nil).should == @list
    end

    it "should return the complete list if we have a blank query" do
      Album.search("").should == @list
    end

    it "should return the result of a DB search if we have a query" do
      Album.should_receive(:all).with(:conditions => ["artist LIKE ? OR name LIKE ?", "%query%", "%query%"]).and_return @list
      Album.search("query").should == @list
    end
  end
end
