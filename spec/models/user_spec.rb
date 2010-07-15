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
end