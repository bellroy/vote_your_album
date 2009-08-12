require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Album do
  
  describe "to hash" do
    before do
      @album = Album.new(:artist => "artist", :name => "album")
    end
    
    it "should map all attributes into a hash" do
      @album.to_hash.should == { :artist => "artist", :name => "album" }
    end
    
    it "should return an empty string if we have a nil artist attribute" do
      @album.artist = nil
      @album.to_hash.should == { :artist => "", :name => "album" }
    end
  end
  
  describe "id hash" do
    before do
      @album = Album.new(:id => "123")
      @album.stub!(:to_hash).and_return({ :one => "two" })
    end
    
    it "should use the to hash method and merge it with the id" do
      @album.id_hash.should == { :one => "two", :id => 123 }
    end
  end
end