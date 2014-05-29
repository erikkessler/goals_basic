require 'spec_helper'

describe FullTask do
  it "has valid factory" do
    FactoryGirl.create(:full_task).should be_valid
  end

  it "is an activity" do
    task = FactoryGirl.create(:full_task)
    task.is_a?(FullTask).should == true
    task.is_a?(Activity).should == true
    FactoryGirl.create(:activity).is_a?(FullTask).should == false
    task.type.should == "FullTask"
  end

  it "is invalid without a name" do
    FactoryGirl.build(:full_task, name: nil).should_not be_valid
  end

  describe "is complete" do
    before :each do
      @dinner = FactoryGirl.create(:full_task, name:"Make Dinner")
      @shop = FactoryGirl.create(:full_task, name:"Shop")
      @cook = FactoryGirl.create(:full_task, name:"Cook")
    end

    context "no children" do
      it "is complete when its state is complete" do
        @dinner.is_complete?.should == false
        @dinner.complete
        @dinner.is_complete?.should == true
        @dinner.incomplete
        @dinner.is_complete?.should == false
      end
    end
    
    context "children" do
      it "is complete when its children are" do
        @dinner.add_child(@shop)
        @dinner.add_child(@cook)
        @dinner.is_complete?.should == false
        @shop.complete
        @dinner.is_complete?.should == false
        @cook.complete
        @dinner.is_complete?.should == true
        @shop.incomplete
        @dinner.is_complete?.should == false
      end

      it "changes state when added_removed" do
        @dinner.add_child(@shop)
        @dinner.add_child(@cook)
        @shop.complete
        @cook.complete
        @dinner.is_complete?.should == true
        table = FactoryGirl.create(:full_task, name:"Set Table")
        @dinner.add_child(table)
        @dinner.is_complete?.should == false
        @dinner.state.should == Activity::INCOMPLETE
        table.make_root
        @dinner.state.should == Activity::COMPLETE
        @dinner.is_complete?.should == true
      end
    end
  end
end
