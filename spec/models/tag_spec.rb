require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Tag do

  describe "find or create by name" do
    before do
      Tag.stub! :first => nil, :create => nil
    end

    it "should return an existing record if it matches the name" do
      Tag.stub!(:first).with(:name => "test").and_return "abc"
      Tag.find_or_create_by_name("test").should == "abc"
    end

    it "should return a new record if we can't find the tag" do
      Tag.stub!(:create).with(:name => "test").and_return "123"
      Tag.find_or_create_by_name("test").should == "123"
    end
  end
end
