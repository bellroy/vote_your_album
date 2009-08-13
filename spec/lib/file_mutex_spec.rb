require File.join(File.dirname(__FILE__) + '/../spec_helper')

describe FileMutex do
  
  describe "synchronize" do
    before do
      @test = Library.new; @test.stub! :lib
      @mutex = FileMutex.new
      @mutex.stub! :sleep
      
      @file = "/tmp/vote_your_album.mutex"
      File.stub! :open
      File.stub! :delete
      File.stub!(:exists?).and_return false
    end
    
    it "should execute the action immediately if we dont have an existing 'mutex file'" do
      @mutex.should_not_receive :sleep
      @test.should_receive :lib
      
      @mutex.synchronize do
        @test.lib
      end
    end
    
    it "should create a file before we execute the action" do
      File.should_receive(:open).with @file, "w"
      
      @mutex.synchronize do
        @test.lib
      end
    end
    
    it "should delete the file after we are finished" do
      File.should_receive(:delete).with @file
      
      @mutex.synchronize do
        @test.lib
      end
    end
    
    describe "mutex locked" do
      before do
        File.stub!(:exists?).and_return true
      end
      
      it "should sleep for 100 ms a hundred times" do
        @mutex.should_receive(:sleep).with(0.1).exactly(100).times
        
        @mutex.synchronize do
          @test.lib
        end
      end
    end
  end
end