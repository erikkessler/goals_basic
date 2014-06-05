# This type of habit is complete when the user has completed the specified 
# number of repititions.
# * Payout only occurs for the whole event. Not for each individual activity.
# * If an expiration date is specified then must reach goal before then
# * Example: Practice piano every mon, wed, fri. Get rewarded if practice 5 
#   times in next 2 weeks

class HabitNumber < Habit

  # must have a goal count
  validates :count_goal, :numericality => { :greater_than => 1 }
  
  # calls complete of repeatable but then checks if rep_parent should change
  def complete
    # get rep_parent
    node = self
    if !self.rep_parent.nil?
      node = self.rep_parent
    end

    # call the super method
    super

    # if not already complete check if reached count_goal
    if node.state != Activity::COMPLETE
      if node.count >= node.count_goal
        node.state = Activity::COMPLETE
        node.completed_date = DateTime.current
        node.save!
      end
    end
  end

  # calls incomplete of repeatable but then checks if rep_parent should change
  def incomplete
    # get rep_parent
    node = self
    if !self.rep_parent.nil?
      node = self.rep_parent
    end

    # call the super method
    super

    # if not already complete check if reached count_goal
    if node.state == Activity::COMPLETE
      if node.count < node.count_goal
        if node.expiration_date.nil? or
            node.expiration_date >= Date.current
          node.state = Activity::INCOMPLETE
        else
          node.state = Activity::COMPLETE
        end
        node.completed_date = nil
        node.save!
      end
    end
  end

  # returns is the state COMPLETE? All calculations of completeness 
  # should be done when the it is completed or incompleted
  def is_complete?
    #get rep_parent
    node = self
    if !self.rep_parent.nil?
      node = self.rep_parent
    end

    node.state == Activity::COMPLETE
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

    # return size * penalty value
    if start_date.nil? or end_date.nil?
      return (node.penalty + child_count)
    elsif node.expiration_date.nil?
      return child_count
    elsif node.expiration_date >= start_date and
        node.expiration_date <= end_date
      return (node.penalty + child_count)
    else
      return child_count
    end
      
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
    
end
