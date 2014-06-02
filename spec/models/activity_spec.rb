require 'spec_helper'

describe Activity do
  it "has a valid factory" do
    FactoryGirl.create(:activity).should be_valid
  end

  it "is invalid without a name" do
    FactoryGirl.build(:activity, name: nil).should_not be_valid
  end

  describe "adding a child" do
    before :each do
      @grades = FactoryGirl.create(:activity, name:"Get Good Grades")
      @math = FactoryGirl.create(:activity, name:"Practice Math")
      @read = FactoryGirl.create(:activity, name:"Read")
    end

    context "no previous parent" do
      it "should set parent and children correctly" do
        @grades.add_child(@math)
        @grades.add_child(@read)
        @grades.reload
        @math.reload
        @read.reload
        @grades.children.order(:name).should == [@math, @read]
        @math.parent.should == @grades
        @read.parent.should_not == @math
      end

      it "should be possible to get to child's child" do
        @grades.add_child(@math)
        @math.add_child(@read)
        @grades.reload
        @math.reload
        @read.reload
        @grades.children[0].children.should == [@read]
        @read.parent.should == @math 
      end
    end
    
    context "previous parent" do
      it "should remove old association" do
        @grades.add_child(@math)
        @math.add_child(@read)
        @grades.add_child(@read)
        @grades.reload
        @math.reload
        @read.reload
        @read.parent.should == @grades
        @math.parent.should == @grades
        @math.children.empty?.should == true
        @grades.children.order(:name).should == [@math,@read]
      end
    end
  end
  
  describe "outdenting" do
    before :each do
      @grades = FactoryGirl.create(:activity, name:"Get Good Grades")
      @math = FactoryGirl.create(:activity, name:"Practice Math")
      @read = FactoryGirl.create(:activity, name:"Read")
    end

    context "from deep level" do
      it "should work using outdent" do
        @grades.add_child(@math)
        @math.add_child(@read)
        @read.outdent
        @grades.reload
        @math.reload
        @read.reload
        @read.parent.should == @grades
        @grades.children.order(:name).should == [@math, @read]
        @math.parent.should == @grades
        @math.children.empty?.should == true
        @read.is_root.should == false
        Activity.where(:is_root => true).should == [@grades]
      end

      it "should work using make_root" do
        @grades.add_child(@math)
        @math.add_child(@read)
        @read.make_root
        @grades.reload
        @math.reload
        @read.reload
        @grades.children.should == [@math]
        @math.children.empty?.should == true
        @read.parent.should == nil
        @read.is_root.should == true
        Activity.where(:is_root => true).order(:name).should == [@grades, @read]
      end
    end
    
    context "from one in" do
      it "should work with outdent" do
        @grades.add_child(@math)
        @math.add_child(@read)
        @math.outdent
        @grades.reload
        @math.reload
        @read.reload
        @read.parent.should == @math
        @grades.children.should == []
        @math.parent.should == nil
        @math.children.should == [@read]
        @math.is_root.should == true
        Activity.where(:is_root => true).order(:name).should == [@grades, @math]
      end

      it "should work with make_root" do
        @grades.add_child(@math)
        @math.add_child(@read)
        @math.make_root
        @grades.reload
        @math.reload
        @read.reload
        @read.parent.should == @math
        @grades.children.empty?.should == true
        @math.parent.should == nil
        @math.children.should == [@read]
        @math.is_root.should == true
        Activity.where(:is_root => true).order(:name).should == [@grades, @math]
      end
    end
    
    context"from root" do
      it "should do nothing with both" do
        @grades.add_child(@math)
        @math.add_child(@read)
        @grades.outdent
        @grades.reload
        @math.reload
        @read.reload
        @grades.is_root.should == true
        @grades.children.should == [@math]
        @math.parent.should == @grades
        @grades.make_root
        @grades.reload
        @math.reload
        @read.reload
        @grades.is_root.should == true
        @grades.children.should == [@math]
        @math.parent.should == @grades
        Activity.where(:is_root => true).order(:name).should == [@grades]
      end
    end
  end
  
  describe "completeing activities"do
    before :each do
      @grades = FactoryGirl.create(:activity, name:"Get Good Grades")
      @math = FactoryGirl.create(:activity, name:"Practice Math")
      @read = FactoryGirl.create(:activity, name:"Read")
      @grades.add_child(@math)
      @math.add_child(@read)
    end

    context "incomplete with activity children" do
      it "should make it and all children complete" do
        Activity.where(:state => 1).size.should == 0
        Activity.where(:state => 0).size.should == 3
        @grades.complete
        @grades.reload
        @math.reload
        @read.reload
        @grades.state.should == 1
        @math.state.should == 1
        @read.state.should == 1
        Activity.where(:state => 1).size.should == 3
        Activity.where(:state => 0).size.should == 0
      end
    end
    context "complete with activity children" do
      it "should make it and all children incomplete" do
        @grades.state = 1
        @math.state = 1
        @read.state = 1
        @grades.save!
        @math.save!
        @read.save!
        Activity.where(:state => 1).size.should == 3
        Activity.where(:state => 0).size.should == 0
        @grades.incomplete
        @grades.reload
        @math.reload
        @read.reload
        @grades.state.should == 0
        @math.state.should == 0
        @read.state.should == 0
        Activity.where(:state => 1).size.should == 0
        Activity.where(:state => 0).size.should == 3
        
      end
    end
  end
  
  describe "deleting activities" do
    before :each do
      @grades = FactoryGirl.create(:activity, name:"Get Good Grades")
      @math = FactoryGirl.create(:activity, name:"Practice Math")
      @read = FactoryGirl.create(:activity, name:"Read")
    end
    context "no children" do
      it "deletes the activty from the database" do
        grades_name = @grades.name
        Activity.all.size.should == 3
        Activity.where(:name => grades_name).size.should == 1
        @grades.remove_act
        Activity.all.size.should == 2
        Activity.where(:name => grades_name).size.should == 0
      end
    end

    context "with children" do
      it "deletes it and children" do
        @grades.add_child(@math)
        @math.add_child(@read)
        Activity.all.size.should == 3
        @grades.remove_act
        Activity.all.size.should == 0
      end
    end
  end
  
  it "returns correct number of children" do
    a = FactoryGirl.create(:activity)
    b = FactoryGirl.create(:activity)
    c = FactoryGirl.create(:activity)
    d = FactoryGirl.create(:activity)
    a.add_child(b)
    a.add_child(c)
    c.add_child(d)
    a.num_children.should == 3
    b.num_children.should == 0
    c.num_children.should == 1
  end

  describe "rewards and payouts" do
    before :each do
      @grades = FactoryGirl.create(:activity, name:"Get Good Grades", reward: 10, penalty: 20)
      @math = FactoryGirl.create(:activity, name:"Practice Math", reward: 5, penalty: 2)
      @read = FactoryGirl.create(:activity, name:"Read", reward: 3, penalty: 0)
    end

    it "calculates correct total possible reward" do
      @grades.add_child(@math)
      @grades.add_child(@read)
      @grades.total_reward.should == 18
      @grades.complete
      @grades.total_reward.should == 18
      @read.incomplete
      @grades.total_reward.should == 18
    end

    it "calculates correct total possible penalty" do
      @grades.add_child(@math)
      @grades.add_child(@read)
      @grades.total_penalty.should == 22
      @grades.complete
      @grades.total_penalty.should == 22
      @read.incomplete
      @grades.total_penalty.should == 22
    end
  end

  describe "payout system" do
    before :each do
      @grades = FactoryGirl.create(:activity, name:"Get Good Grades", reward: 10, penalty: 20)
      @math = FactoryGirl.create(:activity, name:"Practice Math", reward: 5, penalty: 2)
      @read = FactoryGirl.create(:activity, name:"Read", reward: 3, penalty: 0)
      @grades.add_child(@math)
      @math.add_child(@read)
    end

    it "total payout is correct" do
      @grades.total_payout.should == 0
      @grades.complete
      @grades.total_payout.should == 18
      @grades.incomplete
      @grades.total_payout.should == 0
      @read.complete
      @grades.total_payout.should == 3
      @grades.state = Activity::EXPIRED
      @math.state = Activity::EXPIRED
      @grades.total_payout.should == -19
    end

    context "weekly payout" do
      it "returns 0 payout when none completed this week" do
        Timecop.freeze(Date.new(2014,5,30)) do
          @grades.week_payout.should == 0
          @grades.complete
          @grades.completed_date = Date.new(2014, 02, 14)
          @math.completed_date = Date.new(2014, 03, 14)
          @read.completed_date = Date.new(2014, 04, 14)
          @grades.save!
          @math.save!
          @read.save!
          @grades.week_payout.should == 0
          @read.incomplete
          @read.complete
          @grades.week_payout.should == 3
          @math.expiration_date = Date.new(2014, 05, 27)
          @math.state = Activity::EXPIRED
          @math.save
          @grades.week_payout(Date.new(2014,5,30)).should == 1
        end
      end

      it "returns 18 when all completed this week" do
        Timecop.freeze(Date.new(2014,5,30)) do
          @grades.complete
          @grades.week_payout.should == 18
          @grades.expiration_date = Date.new(2014, 05, 27)
          @grades.state = Activity::EXPIRED
          @grades.save!
          @math.expiration_date = Date.new(2014, 05, 27)
          @math.state = Activity::EXPIRED
          @math.save!
          @read.expiration_date = Date.new(2014, 05, 27)
          @read.state = Activity::EXPIRED
          @read.save!
          @grades.week_payout.should == -22
        end
      end
    end
  end
end

