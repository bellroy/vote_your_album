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

      @album.nominate @user
    end

    it "should create a nomination for that album" do
      Time.stub!(:now).and_return time = mock("Now", :tv_sec => 1)
      @album.nominations.should_receive(:create).with :status => "active", :created_at => time, :user => @user
      @album.nominate @user
    end

    it "should also add a up vote immediately for the given user" do
      @nomination.should_receive(:vote).with 1, @user
      @album.nominate @user
    end

    it "should add the songs of the album to the nomination" do
      @album.stub!(:songs).and_return [song = Song.new(:track => 1)]
      @album.nominate @user
      @nomination.songs.should include(song)
    end

    it "should save the nomination again, to persist the songs" do
      @nomination.should_receive :save
      @album.nominate @user
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
      @album = Album.new(:id => 123, :artist => "artist", :name => "album", :art => "some_url")
    end

    it "should return the album's attributes in a hash" do
      @album.to_hash.should == { :id => 123, :artist => "artist", :name => "album", :art => "some_url" }
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

      MpdProxy.stub!(:execute).with(:albums).and_return ["album1"]
      MpdProxy.stub!(:find_songs_for).and_return @songs = [@song]

      Album.stub! :first

      @album = Album.new
      Album.stub!(:new).and_return @album
      @album.stub! :save
      @album.songs.stub!(:first).and_return @song
    end

    it "should fetch all albums from the server" do
      MpdProxy.should_receive(:execute).with(:albums).and_return []
      Album.update
    end

    it "should not do anything if we already have that album in the DB" do
      Album.should_receive(:first).with(:name => "album1").and_return "exists!"
      Album.should_not_receive :build
      Album.update
    end

    it "should build a new album if we dont know it yet" do
      Album.should_receive(:new).with(:name => "album1").and_return @album
      Album.update
    end

    it "should not build an album, if we can't find any songs" do
      MpdProxy.stub!(:find_songs_for).and_return []
      Album.should_not_receive :new
      Album.update
    end

    it "should fetch all the songs for that album from the server" do
      MpdProxy.should_receive(:find_songs_for).with "album1"
      Album.update
    end

    it "should add the found songs to the album" do
      @album.songs.should_receive(:new).with :track => 1, :artist => "me", :title => "song", :length => 123, :file => "path"
      Album.update
    end

    it "should not add duplicate songs" do
      song2 = MPD::Song.new
      { "track" => 2, "artist" => nil, "title" => "song", "album" => "album1", "file" => "other" }.each { |k, v| song2[k] = v }
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

    it "should not use a nil artist if we have a non-nil artist in the song list" do
      @song["title"] = "duplicate"
      Song.stub!(:first).with(:title => "duplicate").and_return true

      @album.songs.should_not_receive :new
      Album.update
    end

    it "should assign a empty value instead of a nil value if we dont have any artists" do
      @song["artist"] = nil
      @album.should_receive(:artist=).with "Unknown"
      Album.update
    end

    it "should take the name of the shortest artist if at least 50% of the song's artist start with the string" do
      @song["artist"] = "longer"
      song2 = MPD::Song.new
      { "track" => 2, "artist" => "MJ", "title" => "song", "album" => "album1", "file" => "other" }.each { |k, v| song2[k] = v }
      song3 = MPD::Song.new
      { "track" => 3, "artist" => "MJ & DJ", "title" => "song", "album" => "album1", "file" => "other" }.each { |k, v| song3[k] = v }
      MpdProxy.stub!(:find_songs_for).and_return [@song, song2, song3]

      @album.should_receive(:artist=).with "MJ"
      Album.update
    end

    it "should assign a 'VA' string if we have to many different artists" do
      song2 = MPD::Song.new
      { "track" => 2, "artist" => "MJ", "title" => "song", "album" => "album1", "file" => "other" }.each { |k, v| song2[k] = v }
      song3 = MPD::Song.new
      { "track" => 3, "artist" => "lala", "title" => "song", "album" => "album1", "file" => "other" }.each { |k, v| song3[k] = v }
      MpdProxy.stub!(:find_songs_for).and_return [@song, song2, song3]

      @album.should_receive(:artist=).with "VA"
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

  describe "nominated" do
    before do
      @album1 = Album.new(:id => 1); @album1.stub!(:nominated?).and_return false
      @album2 = Album.new(:id => 2); @album2.stub!(:nominated?).and_return true
      Album.stub!(:all).and_return @all = [@album1, @album2]
    end

    it "should grab all albums" do
      Album.should_receive(:all).and_return @all
      Album.nominated
    end

    it "should only include albums which have been nominated at least once" do
      Album.nominated.should == [@album2]
    end
  end

  describe "never nominated" do
    before do
      @album1 = Album.new(:id => 1); @album1.stub!(:nominated?).and_return false
      @album2 = Album.new(:id => 2); @album2.stub!(:nominated?).and_return true
      Album.stub!(:all).and_return @all = [@album1, @album2]
    end

    it "should grab all albums" do
      Album.should_receive(:all).and_return @all
      Album.never_nominated
    end

    it "should only include albums which have never been nominated" do
      Album.never_nominated.should == [@album1]
    end
  end

  describe "played" do
    before do
      @album1 = Album.new(:id => 1); @album1.stub!(:played?).and_return false
      @album2 = Album.new(:id => 2); @album2.stub!(:played?).and_return true
      Album.stub!(:all).and_return @all = [@album1, @album2]
    end

    it "should grab all albums" do
      Album.should_receive(:all).and_return @all
      Album.played
    end

    it "should only include albums which have been played" do
      Album.played.should == [@album2]
    end
  end

  describe "random" do
    before do
      @album = Album.new(:id => 1)
      Album.stub!(:get).and_return @album
    end

    it "should return a random album as a list" do
      Album.random.should == [@album]
    end
  end

  describe "most listened" do
    it "should query the database directly for the most listened albums" do
      Album.should_receive(:execute_sql).with "COUNT(DISTINCT n.id)", "n.status = 'played'"
      Album.most_listened
    end
  end

  describe "most popular" do
    it "should query the database directly for the most popular" do
      Album.should_receive(:execute_sql).with "SUM(v.value) / COUNT(DISTINCT n.id)", "v.type = 'vote' AND v.value > 0"
      Album.most_popular
    end
  end

  describe "least popular" do
    it "should query the database directly for the least popular" do
      Album.should_receive(:execute_sql).with "SUM(v.value) / COUNT(DISTINCT n.id)", "v.type = 'vote' AND v.value < 0", "ASC"
      Album.least_popular
    end
  end
end
