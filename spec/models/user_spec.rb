require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  
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