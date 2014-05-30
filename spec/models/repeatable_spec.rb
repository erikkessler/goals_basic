require 'spec_helper'

describe Repeatable do

  it "has valid factory" do
    create(:repeatable).should be_valid
  end

  it "is invalid without a name" do
    build(:repeatable, name: nil).should_not be_valid
  end

  it "is an activity" do
    rep = create(:repeatable)
    rep.is_a?(Activity).should == true
    rep.is_a?(Repeatable).should == true
    rep.is_a?(FullTask).should == false
  end

  describe "generating repititions" do
    context "no chilren" do
      before :each do
        @repable = create(:daily_repeatable)
      end
      it "sets rep_parent of reps to it" do
        @repable.gen_reps
        @repable.repititions[0].rep_parent.should == @repable
      end

      it "returns parent of rep_parent" do
        act = create(:activity)
        act.add_child(@repable)
        @repable.parent.should == act
        @repable.gen_reps
        @repable.repititions[0].parent.should == act
      end

      it "returns only rep_parent when children called" do
        act = create(:activity)
        act.add_child(@repable)
        @repable.gen_reps
        act.children.should == [@repable]
      end

      it "creates correct show_dates" do
        mwf = create(:mwf_repeatable)
        mwf.gen_reps(Date.today.next_week(:monday), Date.today.next_week(:friday))
        the_reps = mwf.repititions.order(:show_date)
        the_reps[0].show_date.should ==
          Date.today.next_week(:monday)
        the_reps[1].show_date.should ==
          Date.today.next_week(:wednesday)
        the_reps[2].show_date.should ==
          Date.today.next_week(:friday)
      end

      it "generates correct # of reps" do
        @repable.repititions.size.should == 0
        @repable.gen_reps
        @repable.repititions.size.should == 8
        mwf = create(:mwf_repeatable)
        mwf.gen_reps
        mwf.repititions.size.should == 4
      end
    end

    it "set_repeated sets to set value" do
      rep = create(:repeatable)
      rep.set_repeated([0,1,5,6])
      rep.repeated.should == 1326
      rep.get_repeated.should == [0,1,5,6]
      rep.set_repeated([0,1,2,3,4,5,6])
      rep.repeated.should == 510510
      rep.get_repeated.should == [0,1,2,3,4,5,6]
    end

    it "gets added to parent correctly" do
      repable = create(:mwf_repeatable)
      repable.gen_reps
      act = create(:activity)
      act.add_child(repable.repititions[0])
      repable.reload
      act.children.should == [repable]
      repable.parent.should == act
      repable.repititions[0].parent.should == act
      repable.repititions[0].parent_id.should == nil
    end
    
    describe "deleting reps" do
      before :each do
        @repable = create(:daily_repeatable)
        @repable.gen_reps
      end

      it "deletes future reps" do
        number = Activity.all.size
        @repable.del_reps
        @repable.repititions.where("show_date > :date", date: Date.current).size.should == 0
        Activity.all.size.should_not == number
      end
      
      it "keeps past events" do 
        number = @repable.repititions.where("show_date <= :date", date: Date.current)
        @repable.del_reps
        @repable.repititions.where("show_date <= :date", date: Date.current).should == number
      end

      it "works on the reps" do
        number = @repable.repititions.size
        @repable.repititions[0].del_reps
        @repable.reload
        @repable.repititions.size.should_not == number
      end
    end
  end
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
  end
end
