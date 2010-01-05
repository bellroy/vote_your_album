require File.join(File.dirname(__FILE__) + '/../../spec_helper')

describe Fixnum do

  describe "to time" do

    { 0 => "-00:00", 1 => "-00:01", 60 => "-01:00", 123 => "-02:03", 3599 => "-59:59",
      3600 => "-01:00:00", 3661 => "-01:01:01", 7199 => "-01:59:59" }.each do |seconds, time|
      it "should return the formatted value ('#{time}') of the given number: #{seconds}" do
        seconds.to_time.should == time
      end
    end
  end
end
