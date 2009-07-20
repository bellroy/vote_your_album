require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Library do
  
  describe "list" do
    it "should provide read and write methods for 'list'" do
      Library.should respond_to(:list)
      Library.should respond_to(:list=)
    end
    
    it "should sort the list by album name" do
      Library.list = [Album.new(1, "b", 0), Album.new(2, "a", 0)]
      Library.list.first.name.should == "a"
    end
  end
  
  describe "next" do
    it "should provide read and add methods for 'next'" do
      Library.should respond_to(:next)
      Library.should respond_to(:<<)
    end
    
    it "should add an album to the next list when '<<' is called" do
      album = Album.new(1, "a", 0)
      Library << album
      Library.next.should include(album)
    end
  end
end