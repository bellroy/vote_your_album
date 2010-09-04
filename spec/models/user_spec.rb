require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe User do

  describe "create from profile" do
    before do
      User.stub! :create
    end

    it "should create a user with the given profile attributes" do
      User.should_receive(:create).with hash_including(:identifier => "abc", :username => "m.self", :name => "my self")
      User.create_from_profile "identifier" => "abc", "preferredUsername" => "m.self", "displayName" => "my self"
    end

    it "should use the given name of the user, if present" do
      User.should_receive(:create).with hash_including(:name => "my")
      User.create_from_profile "name" => { "givenName" => "my", "familyName" => "self" }
    end
  end

  describe "toogle favourite" do
    before do
      @album = Album.create(:artist => "Beatsteaks", :name => "Limbo Messiah")
      @user = User.create(:name => "Me")
    end

    it "should add the album to the favourites if it's not starred" do
      @user.toggle_favourite @album

      @user.reload
      @user.favourite_albums.should include(@album)
    end

    it "should remove the album from the favourites if it's starred" do
      @user.favourite_albums << @album
      @user.save

      @user.toggle_favourite @album

      @user.reload
      @user.favourite_albums.should be_empty
    end
  end
end