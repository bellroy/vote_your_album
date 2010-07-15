require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe User do

  describe "create from profile" do
    before do
      User.stub! :create
    end

    it "should create a user with the given profile attributes" do
      User.should_receive(:create).with hash_including(:identifier => "abc", :username => "my self")
      User.create_from_profile "identifier" => "abc", "preferredUsername" => "my self"
    end
  end
end