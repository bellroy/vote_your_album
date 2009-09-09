require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  
  describe "has name?" do
    before do
      @user = User.new
    end
    
    it "should return false if the name is nil" do
      @user.should_not have_name
    end
    
    it "should return false if the name is empty" do
      @user.name = ""
      @user.should_not have_name
    end
    
    it "should return true if we have a non empty string" do
      @user.name = "me"
      @user.should have_name
    end
  end
  
  describe "get or create by" do
    before do
      User.stub!(:first).and_return @user = User.new
      User.stub! :create
    end
    
    it "should return the user with the given ip if we can find one" do
      User.should_receive(:first).with(:ip => "me").and_return @user
      User.get_or_create_by("me").should == @user
    end
    
    it "should create a user with the new ip if we cant find one" do
      User.should_receive(:first).and_return nil
      User.should_receive(:create).with(:ip => "me").and_return @user
      User.get_or_create_by("me").should == @user
    end
  end
end