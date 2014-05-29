require 'spec_helper'

describe PartialTask do

  it "has valid factory" do
    FactoryGirl.create(:partial_task).should be_valid
  end

  it "is an activity" do
    task = FactoryGirl.create(:partial_task)
    task.is_a?(Activity).should == true
    task.is_a?(FullTask).should == false
    task.is_a?(PartialTask).should == true
    task.type.should == "PartialTask"
  end
  
  describe "is complete" do
    it "should only return state" do
      dinner = FactoryGirl.create(:partial_task)
      shop = FactoryGirl.create(:partial_task)
      cook = FactoryGirl.create(:partial_task)
      dinner.is_complete?.should == false
      dinner.add_child(shop)
      dinner.add_child(cook)
      dinner.complete
      shop.is_complete?.should == false
      dinner.is_complete?.should == true
      shop.complete
      cook.complete
      dinner.incomplete
      dinner.is_complete?.should == false
    end
  end


  
end
