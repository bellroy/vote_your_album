require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Library do
  
  describe "list" do
    before do
      Library.class_eval do
        @list = []
      end
    end
    
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
    before do
      Library.class_eval do
        @next = []
      end
    end
    
    it "should provide read and add methods for 'next'" do
      Library.should respond_to(:next)
      Library.should respond_to(:<<)
    end
    
    it "should add an album to the next list when '<<' is called" do
      album = Album.new(1, "a", 0)
      Library << album
      Library.next.should include(album)
    end
    
    it "should sort the list by number of votes" do
      Library << album1 = Album.new(1, "a", 0)
      Library << album2 = Album.new(2, "b", 1)
      Library.next.should == [album2, album1]
    end
  end
end

describe Album do
  
  describe "vote" do
    before do
      @album = Album.new(1, "album", 0)
    end
    
    [0, 1, -1, 4, -3].each do |by|
      it "should change the votes by #{by}" do
        @album.vote by
        @album.votes.should == by
      end
    end
  end
end