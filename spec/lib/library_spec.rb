require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe Library do
  
  describe "leaf paths of" do
    it "returns a path, if it doesn't have a sub dir in the list" do
      Library.leaf_paths_of(["a"]).should == ["a"]
    end

    it "keeps unrelated paths" do
      Library.leaf_paths_of(["a", "b"]).should == ["a", "b"]
    end

    it "removes the base path if we have a subdir for it" do
      Library.leaf_paths_of(["a", "a/aa"]).should == ["a/aa"]
    end

    it "keeps all sub dirs of the base path" do
      Library.leaf_paths_of(["a", "a/aa", "a/ab", "a/ac"]).should == ["a/aa", "a/ab", "a/ac"]
    end

    it "doesn't touch unrelated paths if a base dir is removed" do
      Library.leaf_paths_of(["a", "a/aa", "b"]).should == ["a/aa", "b"]
    end

    it "removes all base paths if they all have sub dirs" do
      Library.leaf_paths_of(["a", "a/aa", "b", "b/bb"]).should == ["a/aa", "b/bb"]
    end

    it "makes sure we only get leaves" do
      Library.leaf_paths_of(["a", "a/aa", "a/aa/aaa"]).should == ["a/aa/aaa"]
    end

    it "leaves similar named subdirs in another base path alone" do
      Library.leaf_paths_of(["a", "a/aa", "b", "b/a", "b/aa"]).should == ["a/aa", "b/a", "b/aa"]
    end

    it "keeps similar named subdirs in another base path if nested further" do
      Library.leaf_paths_of(["a", "a/aa", "a/aa/aaa", "b", "b/aa"]).should == ["a/aa/aaa", "b/aa"]
    end

    it "handles regular brackets in the path" do
      Library.leaf_paths_of(["a", "a/aa (123)"]).should == ["a/aa (123)"]
    end

    it "handles square brackets in the path" do
      Library.leaf_paths_of(["a", "a/aa [123]"]).should == ["a/aa [123]"]
    end

    it "handles square brackets with a dash in the path" do
      Library.leaf_paths_of(["a", "a/aa [mp3-123-456]"]).should == ["a/aa [mp3-123-456]"]
    end
  end
end
