# This type of habit requires a certain number of completions per week
# for a certain number of weeks to be complete. An expiration date determines
# how many weeks a person has to complete the goal.
# </br>For example, Practice SAT 4 times a week for 3 weeks

class HabitDate < Habit

  # validations
  validates :expiration_date, presence: true, :if => :is_rep_parent?
  validates :count_goal, :numerically => { :greater_than => 1 }
  def is_rep_parent
    return self.rep_parent.nil?
  end
  
  # generates reps for the given range
  # period is the number of days in the future to set the expiration date
  def gen_reps(start_date = Date.current,
               end_date = Date.current.advance(:weeks => 1), period = 1)
    node= self
    if !self.rep_parent.nil?
      node = self.rep_parent
    end
    
    node.super(Date.current, node.expiration_date, period)
  end

  # just return reward as that is the total possible
  def total_reward(start_date = nil, end_date = nil)
    # select rep_parent if it exists
    node = self
    if !self.rep_parent.nil?
      node = self.rep_parent
    end
    
    # recusivly count children
    child_count = 0
    node.children.each do |child|
      child_count = child_count + child.total_reward(start_date, end_date)
    end

    # return size * reward value
    return (node.reward + child_count)
  end

  # return penalty if there an expiration as that is the total possible penalty
  def total_penalty(start_date = nil, end_date = nil)
    # select rep_parent if it exists
    node = self
    if !self.rep_parent.nil?
      node = self.rep_parent
    end
    
    # recusivly count children
    child_count = 0
    node.children.each do |child|
      child_count = child_count + child.total_penalty(start_date, end_date)
    end

    # return penalty value
    return (node.penalty + child_count)
  
  end

  # return the reward if complete or the penalty if expired
  def total_payout
    # make sure we have rep_parent
    node = self
    if !self.rep_parent.nil?
      node = self.rep_parent
    end
    
    # get total payout of children
    child_payout = 0
    node.children.each do |child|
      child_payout = child_payout + child.total_payout
    end

    # if COMPLETE add reward, if EXPIRED subtract penalty
    if node.state == Activity::COMPLETE
      return child_payout + node.reward
    elsif node.state ==Activity::EXPIRED
      reuturn child_payout - node.penalty
    else
      return child_payout
    end
  end

  # payout for the specified week
  # date specifies which week want to check
  # start_day specifies day of week to start on
  def week_payout(date = Date.current, start_day = "monday")
    if !date.is_a? Date
      puts "Must pass in a date"
      return
    end

    # make sure using rep_parent
    node = self
    if !self.rep_parent.nil?
      node = self.rep_parent
    end
    
    # calculate start and end of week
    week_start = date.
      beginning_of_week(start_date = start_day.to_sym)
    week_end =  date.
      end_of_week(start_date = start_day.to_sym)
    date_range = week_start..week_end
    
    # get payout of children
    count = 0 
    node.children.each do |child|
      count = count + child.week_payout(date, start_day)
    end
    
    # get reward/ penalty
    act_payout = 0
    if node.state == Activity::COMPLETE and 
        date_range.include? node.completed_date
      act_payout = node.reward
    elsif node.state == Activity::EXPIRED and
        date_range.include? node.expiration_date
      act_payout = -1 * node.penalty
      
    end
    
    return count + act_payout
  end

  # marks complete if child or marks rep of the day
  # if # that week = count then decrement count_goal
  # does not impact children
  # week start is the day of week to start week on 
  def complete(start_day = "monday")
    # check if an individual rep, complete reps of day if not
    if self.rep_parent.nil?
      self.repititions.
        where(:show_date => Date.current).each do |rep|
        rep.complete
      end
      return
    end

    if self.state != Activity::COMPLETE
      self.state = Activity::COMPLETE
      self.completed_date = DateTime.current
      self.save!
      # calculate start and end of week
      date = Date.current
      week_start = date.
        beginning_of_week(start_date = start_day.to_sym)
      week_end =  date.
        end_of_week(start_date = start_day.to_sym)
    
      week_reps = self.rep_parent.repititions.
        where("completed_date >= ? AND completed_date <= ?",
              week_start, week_end)
      if week_reps.size = self.rep_parent.count
        week_count = self.rep_parent.count_goal - 1
        self.rep_parent.count_goal = week_count
        if week_count == 0
          self.rep_parent.state = Activity::COMPLETE
          self.rep_parent.competed_date = DateTime.current
          self.rep_parent.save!
        end
      end
    end
  end

  # marks incomplete if child or marks rep of the day
  # if # that week < count then increment count_goal
  # does not impact children
  # week start is the day of week to start week on 
  def incomplete(start_day = "monday")
    # check if an individual rep, complete reps of day if not
    if self.rep_parent.nil?
      self.repititions.
        where(:show_date => Date.current).each do |rep|
        rep.incomplete
      end
      return
    end

    # if not already complete check if reached count_goal
    if self.state == Activity::COMPLETE
      if self.expiration_date.nil? or
          self.expirration_date >= Date.current
        self.state = Activity::INCOMPLETE
      else
        self.state = Activity::COMPLETE
      end
      self.completed_date = nil
      self.save!
      
      # if rep_parent is complete may have to change
      node = self.rep_parent
      if node.state == Activity::COMPLETE
        date = Date.current
        week_start = date.
          beginning_of_week(start_date = start_day.to_sym)
        week_end =  date.
          end_of_week(start_date = start_day.to_sym)
        
        # get number completed this week
        week_reps = node.repititions.
          where("completed_date >= ? AND completed_date <= ?",
                week_start, week_end)

        # if less then increment count_goal
        if week_reps.size < node.count
          week_count = node.count_goal + 1
          node.count_goal = week_count
          # if goal_count is now 1 then not complete anymore
          if week_count == 1
            if  node.expiration_date >= Date.current
              node.state = Activity::INCOMPLETE
            else
              node.state = Activity::EXPIRED
            end
            node.competed_date = nil
            node.rep_parent.save!
          end
        end
      end
    end
  end

end
