require 'spec_helper'

describe Activity do
  it "has a valid factory" do
    FactoryGirl.create(:activity).should be_valid
  end
  it "is invalid without a name" do
    FactoryGirl.build(:activity, name: nil).should_not be_valid
  end
  it "returns an activity's name as a string"
end
