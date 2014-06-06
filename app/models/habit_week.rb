# This type of habit requires a certain number of completions per week
# for a certain number of weeks to be complete. An expiration date determines
# how many weeks a person has to complete the goal.
# </br>For example, Practice SAT 4 times a week for 3 weeks
# If the count_goal is less than 0 then there is no number of weeks need to do it for
# - reward is paid for each complete week.

class HabitWeek < Habit
  INFINITE_WEEKS = -1

  # just return reward as that is the total possible
  def total_reward(start_date = nil, end_date = nil)
    # select rep_parent if it exists
    node = self.get_rep_parent
    
    # recusivly count children
    child_count = 0
    node.children.each do |child|
      child_count = child_count + child.total_reward(start_date, end_date)
    end

    # if no week requirement then count number of weeks 
    if node.is_infinite? and !start_date.nil? and !end_date.nil?
      weeks = ((end_date - start_date)/7).to_i
      return ((weeks * node.reward) + child_count)
    else
      return (node.reward + child_count)
    end
  end

  # return penalty if there an expiration as that is the total possible penalty
  def total_penalty(start_date = nil, end_date = nil)
    # select rep_parent if it exists
    node = self.get_rep_parent
    
    # recusivly count children
    child_count = 0
    node.children.each do |child|
      child_count = child_count + child.total_penalty(start_date, end_date)
    end

    # if no week requirement then count number of weeks 
    if node.is_infinite? and !start_date.nil? and !end_date.nil?
      weeks = ((end_date - start_date)/7).to_i
      return ((weeks * node.penalty) + child_count)
    else
      return (node.penalty + child_count)
    end
  
  end

  # return the reward if complete or the penalty if expired
  def total_payout
    # make sure we have rep_parent
    node = self.get_rep_parent
    
    # get total payout of children
    child_payout = 0
    node.children.each do |child|
      child_payout = child_payout + child.total_payout
    end

    # if no week requirement then number reward - penalty
    if node.is_infinite?
      rewards = node.get_weeks_complete
      penalties = node.get_weeks_expired
      return (rewards * node.reward) - (penalties * node.penalty) + child_payout
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
    node = self.get_rep_parent

    # calculate start and end of week
    week_start = date.
      beginning_of_week(start_date = start_day.to_sym)
    week_end =  date.
      end_of_week(start_date = start_day.to_sym)
    date_range = week_start..week_end
    
    # get payout of children
    child_payout = 0 
    node.children.each do |child|
      child_payout += child.week_payout(date, start_day)
    end

    # if no week requirement
    if node.is_infinite?
      # get all from this week
      week_reps = self.rep_parent.repititions.
        where("completed_date >= ? AND completed_date <= ?",
              week_start, week_end)
      if week_reps >= node.count
        return node.reward + child_payout
      elsif Date.current > week_end
        return node.penalty + child_payout
      else
        return child_payout
      end
        
    end
    
    
    # there is a week requirement, get reward/ penalty
    act_payout = 0
    if node.state == Activity::COMPLETE and 
        date_range.include? node.completed_date
      act_payout = node.reward
    elsif node.state == Activity::EXPIRED and
        date_range.include? node.expiration_date
      act_payout = -1 * node.penalty
      
    end
    
    return child_payout + act_payout
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

       # if rep_parent is complete may have to change
      node = self.rep_parent
      if node.state != Activity::COMPLETE 
        # calculate start and end of week
        date = Date.current
        week_start = date.
          beginning_of_week(start_date = start_day.to_sym)
        week_end =  date.
          end_of_week(start_date = start_day.to_sym)
        
        week_reps = node.repititions.
          where("completed_date >= ? AND completed_date <= ?",
                week_start, week_end)

        if week_reps.size >= node.count
          week_count = node.add_complete_week
          if week_count <= 0
            node.state = Activity::COMPLETE
            node.competed_date = DateTime.current
          end
          node.save!
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

    # if not already incomplete check if still at count_goal
    if self.state == Activity::COMPLETE
      if self.expiration_date.nil? or
          self.expiration_date >= Date.current
        self.state = Activity::INCOMPLETE
      else
        self.state = Activity::EXPIRED
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
          node.add_incomplete_week
          if  node.expiration_date.nil? or node.expiration_date >= Date.current
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

  def is_infinite?
    node = self.get_rep_parent
    return node.count_goal < 0
  end

  def set_weeks(weeks)
    node = self.get_rep_parent
    if weeks.nil? or weeks == INFINITE_WEEKS
      node.count_goal = (-1 * node.get_weeks_complete) + INFINITE_WEEKS
      node.save!
    else
      node.count_goal = node.get_weeks_complete + (weeks * 1000)
      node.save!
    end
  end

  def get_weeks_complete
    node = self.get_rep_parent
    if node.count_goal.nil?
      return 0
    elsif node.is_infinite?
      return ((1000 - (node.count_goal % 1000)) - 1)
    else
      return (node.count_goal % 1000)
    end
  end

  def get_expired_weeks
    node = self.get_rep_parent
    if node.is_infinite?
      return ((node.count_goal / 1000) * -1)
    else
      return nil
    end
  end

  def weeks_needed
    node = self.get_rep_parent
    if node.is_infinite?
      return nil
    else
      return (node.count_goal / 1000)
    end
  end

  protected
  def add_complete_week
    node = self.get_rep_parent
    if node.is_infinite?
      node.count_goal -= 1
    else
      node.count_goal += 1
    end
  end

  def add_incomplete_week
    node = self.get_rep_parent
    if node.is_infinite?
      node.count_goal -= 999
    else
      node.count_goal -= 1
    end
  end

  def get_rep_parent
    if self.rep_parent.nil?
      return self
    else
      return self.rep_parent
    end
  end
end
