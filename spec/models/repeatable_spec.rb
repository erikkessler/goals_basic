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
        Timecop.freeze(Date.new(2014,5,31)) do
          @repable.repititions.size.should == 0
          @repable.gen_reps
          @repable.repititions.size.should == 8
          mwf = create(:mwf_repeatable)
          mwf.gen_reps
          mwf.repititions.size.should == 3
        end
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

    describe "moving tasks" do
      before :each do
        @weekend = create(:weekend_repeatable)
        @mwf = create(:mwf_repeatable)
        
      end
      
      it "add_child adds to the rep parent" do
        @weekend.add_child(@mwf)
        @weekend.children.should == [@mwf]
        @mwf.parent.should == @weekend
        @mwf.make_root
        @weekend.gen_reps
        @mwf.gen_reps
        @weekend.repititions[0].add_child(@mwf.repititions[0])
        @weekend.children.should == [@mwf]
        @mwf.reload
        @mwf.parent.should == @weekend
      end

      it "children on a individual returns that day's child" do
        Timecop.freeze(Date.new(2014,5,30)) do
          @weekend.add_child(@mwf)
          act = create(:activity, show_date: Date.new(2014,5,31))
          @weekend.add_child(act)
          @mwf.set_repeated([1,3,5,6])
          @weekend.gen_reps
          @mwf.gen_reps
          date  = Date.new(2014,5,31)
          @weekend.repititions.where(:show_date => date)[0].children.should == @mwf.repititions.where(:show_date => date) << act
          end
      end

      it "make_root makes rep_parent root" do
        @weekend.add_child(@mwf)
        @mwf.is_root.should == false
        @mwf.gen_reps
        @mwf.repititions[0].make_root
        @mwf.reload
        @mwf.is_root.should == true
      end

      it "outdent works on the rep_parent" do
        @weekend.add_child(@mwf)
        act = create(:activity)
        act.add_child(@weekend)
        @mwf.gen_reps
        @mwf.repititions[0].outdent
        act.children.should == [@weekend, @mwf]
      end
    end

    describe "reward system" do
      before :each do
        @daily = create(:daily_repeatable, :high_reward, :low_penalty)
        @daily.gen_reps
        @daily.repititions.each do |rep|
          if rep.id % 4 == 0
            rep.state = Activity::COMPLETE
            rep.completed_date = DateTime.new(2014,3,14)
            rep.expiration_date = Date.new(2014,3,14)
            rep.show_date = DateTime.new(2014,3,14)
            rep.save!
          elsif rep.id % 4 == 2
            rep.state = Activity::COMPLETE
            rep.completed_date = DateTime.new(2014,3,7)
            rep.expiration_date = Date.new(2014,3,7)
            rep.show_date = DateTime.new(2014,3,7)
            rep.save!
          elsif rep.id % 4 == 1
            rep.state = Activity::EXPIRED
            rep.expiration_date = Date.new(2014,3,14)
            rep.show_date = DateTime.new(2014,3,14)
            rep.save!
          else
            rep.state = Activity::EXPIRED
            rep.expiration_date = Date.new(2014,3,7)
            rep.show_date = DateTime.new(2014,3,7)
            rep.save!
          end
        end
        
      end

      it "returns correct total payout" do
        Timecop.freeze(Date.new(2014,3,15)) do
          @daily.total_payout.should == 180
          @daily.repititions[0].total_payout.should == 180
        end
      end

      it "returns correct weekly payout" do
        @daily.week_payout(Date.new(2014,3,15), "sunday").should == 90
        @daily.repititions[0].week_payout(Date.new(2014,3,15), "sunday").should == 90
      end

      it "returns correct total reward" do
        @daily.total_reward.should == 400
        @daily.repititions[0].total_reward(Date.new(2014,3,9), Date.new(2014,3,15)).should == 200
      end

      it "returns correct total penalty" do
        @daily.total_penalty.should == 40
        @daily.repititions[0].total_penalty(Date.new(2014,3,9), Date.new(2014,3,15)).should == 20
      end
    end
    
    it "removes from database on remove_act" do
      daily = create(:daily_repeatable)
      act = create(:activity)
      daily.gen_reps
      daily.add_child(act)
      old_size = Activity.all.size
      daily.remove_act
      Activity.all.size.should_not == old_size
      Activity.all.size.should == 0
    end

    describe "completing and incompleting" do
      before :each do
        @daily = create(:daily_repeatable)
        @daily.gen_reps(Date.new(2014,3,8), Date.new(2014,3,14), 1)
        @daily.repititions.where(:show_date => Date.new(2014, 3, 8))[0].state = Activity::EXPIRED
        @daily.repititions.where(:show_date => Date.new(2014, 3, 9))[0].state = Activity::COMPLETE
        @daily.repititions.where(:show_date => Date.new(2014, 3, 9))[0].completed_date = DateTime.new(2014, 3, 9)
        @daily.repititions.where(:show_date => Date.new(2014, 3, 10))[0].state = Activity::INCOMPLETE
        @daily.repititions.where(:show_date => Date.new(2014, 3, 11))[0].state = Activity::INCOMPLETE
        @act = create(:activity, show_date: Date.new(2014, 3, 11))
        @daily.add_child(@act)                         
      end

      it "incomplete leaves expired as expired" do
        Timecop.freeze(Date.new(2014,3,11)) do
          @daily.repititions.where(:show_date => Date.new(2014, 3, 8))[0].complete
          @daily.repititions.where(:show_date => Date.new(2014, 3, 8))[0].incomplete
          @daily.repititions.where(:show_date => Date.new(2014, 3, 8))[0].state.should == Activity::EXPIRED
        end
      end
      
      it "incomplete makes expired complete expired" do
        Timecop.freeze(Date.new(2014,3,11)) do
          @daily.repititions.where(:show_date => Date.new(2014, 3, 9))[0].complete
          @daily.repititions.where(:show_date => Date.new(2014, 3, 9))[0].incomplete
          @daily.repititions.where(:show_date => Date.new(2014, 3, 9))[0].state.should == Activity::EXPIRED
          @daily.repititions.where(:show_date => Date.new(2014, 3, 9))[0].completed_date.should == nil
        end
      end

      it "incomplete makes inexpired complete incomplete" do
        Timecop.freeze(Date.new(2014,3,10)) do
          @daily.repititions.where(:show_date => Date.new(2014, 3, 9))[0].incomplete
          @daily.repititions.where(:show_date => Date.new(2014, 3, 9))[0].state.should == Activity::INCOMPLETE
          @daily.repititions.where(:show_date => Date.new(2014, 3, 9))[0].completed_date.should == nil
        end
      end

      it "incomplete leave incomplete" do
        Timecop.freeze(Date.new(2014,3,11)) do
          @daily.repititions.where(:show_date => Date.new(2014, 3, 10))[0].incomplete
          @daily.repititions.where(:show_date => Date.new(2014, 3, 10))[0].state.should == Activity::INCOMPLETE
          @daily.repititions.where(:show_date => Date.new(2014, 3, 10))[0].completed_date.should == nil
        end
      end

      it "complete completes incomplete" do
        Timecop.freeze(Date.new(2014,3,11)) do
          @daily.repititions.where(:show_date => Date.new(2014, 3, 10))[0].complete
          @daily.repititions.where(:show_date => Date.new(2014, 3, 10))[0].state.should == Activity::COMPLETE
          @daily.repititions.where(:show_date => Date.new(2014, 3, 10))[0].completed_date.should == Date.new(2014,3,11)
        end
      end

      it "complete makes day's rep complete" do
        Timecop.freeze(Date.new(2014,3,11)) do
          @daily.complete
          @daily.repititions.where(:show_date => Date.new(2014, 3, 11))[0].state.should == Activity::COMPLETE
          @daily.repititions.where(:show_date => Date.new(2014, 3, 11))[0].completed_date.should == Date.current
          @act.state.should == Activity::INCOMPLETE
        end
      end
    end
  end
end
