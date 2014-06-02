require 'spec_helper'

describe Habit do
  
  it "has a valid factory" do
    create(:habit).should be_valid
  end

  it "is invalid without a name" do
    build(:habit, name: nil).should_not be_valid
  end

  it "is an activity" do
    rep = create(:habit)
    rep.is_a?(Activity).should == true
    rep.is_a?(Repeatable).should == true
    rep.is_a?(Habit).should == true
    rep.is_a?(FullTask).should == false
  end
  
  it "sets state to ARCHIVED_HABIT" do
    habit = create(:habit)
    habit.remove_act
    habit.state.should == Activity::ARCHIVED_HABIT
  end
  
  it "calls remove_act on children" do
    habit = create(:habit)
    act = create(:activity)
    habit.add_child(act)
    habit.remove_act
    lambda {act.reload}.should raise_error
  end

  describe HabitNumber do
    
    it "has valid factory" do
      create(:habitnumber).should be_valid
    end

    it "is an activity and repeatable" do
      habit = create(:habitnumber)
      habit.is_a?(Activity).should == true
      habit.is_a?(Repeatable).should == true
    end

    describe "completing" do
      before :each do
        @habit = create(:habitnumber)
        
      end
      it "sets a rep as complete" do
        @habit.gen_reps(Date.new(2014,3,8), Date.new(2014,3,14))
        rep = @habit.repititions[0]
        rep.complete
        rep.state.should == Activity::COMPLETE
        @habit.reload
        @habit.count.should == 1
      end

      it "sets rep_parent as complete when goal" do
        @habit.gen_reps(Date.new(2014,3,8), Date.new(2014,3,14))
        @habit.is_complete?.should == false
        @habit.repititions.each do |rep|
          rep.complete
        end
        @habit.reload
        @habit.is_complete?.should == true
        @habit.state.should == Activity::COMPLETE
      end

      it "sets reps of day as complete" do
        @habit.gen_reps(Date.new(2014,3,8), Date.new(2014,3,14))
        Timecop.freeze(Date.new(2014,3,10)) do
          @habit.complete
          rep = @habit.repititions.where(:show_date => Date.new(2014,3,10))[0]
          rep.state.should == 1
          @habit.reload
          @habit.count.should == 1
        end
      end
    end
    describe "incompleting" do
      before :each do
        @habit = create(:habitnumber)
        @habit.gen_reps(Date.new(2014,3,8), Date.new(2014,3,14))
        @rep = @habit.repititions.where(:show_date => Date.new(2014,3,10))[0]
        
      end
      it "sets rep as incomplete if before ex" do
        Timecop.freeze(Date.new(2014,3,8)) do
          @rep.complete
          @habit.reload
          @habit.count.should == 1
          @rep.incomplete
          @habit.reload
          @habit.count.should == 0
          @rep.state.should == Activity::INCOMPLETE
        end
      end

      it "sets as expired if after" do
        Timecop.freeze(Date.new(2014,3,12)) do
          @rep.complete
          @rep.incomplete
          @rep.state.should == Activity::EXPIRED
       
        end
      end

      it "sets rep of day as incomplete" do
        Timecop.freeze(Date.new(2014,3,10)) do
          @habit.incomplete
          @rep.state.should == Activity::INCOMPLETE
        end
      end
    end
  end
end
