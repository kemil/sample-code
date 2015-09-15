require 'spec_helper'

describe Address do

  it "has a constant array of regions" do
    Address::REGIONS.should == ["NSW", "QLD", "VIC", "SA", "WA", "NT", "ACT", "TAS"]
  end

end
