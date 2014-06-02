# A subclass of Activity that allows for repeated events.
# Methods to generate the repeated tasks and manipulate them.
# Use the extension of this class, Habit, for most cases.

class Repeatable < Activity

  # used to calculate repeated days
  DAY_VALUES = {0 => 2, 1 => 3, 2 => 5, 3 => 7, 4 => 11, 5 => 13, 6 => 17}
  
  # used to indicate no expiration on repititions
  NO_EXPIRATION = -1

  # inheritance
  self.inheritance_column = :type
  scope :habits, -> { where(type:'Habit') }

  # allow to track its repititions
  has_many :repititions, class_name: "Repeatable",
    foreign_key: "rep_parent_id"
  belongs_to :rep_parent, class_name: "Repeatable", foreign_key: "rep_parent_id"


  # generates reps for the given range
  # period is the number of days in the future to set the expiration date
  # Use a -1 period to indicate no expiration
  def gen_reps(start_date = Date.current,
               end_date = Date.current.advance(:weeks => 1), period = 1)

    # must be the rep_parent
    if !self.rep_parent.nil?
      self.rep_parent.gen_reps(start_date, end_date, period)
      return
    end

    # check dates are dates
    if !start_date.is_a?(Date) or !end_date.is_a?(Date)
      puts "start_date and end_date must be dates"
      return
    end

    # make sure start before end
    if start_date > end_date
      puts "start_date after end_date"
      return
    end

    #check each day in date range
    date_range = start_date..end_date
    date_range.each do |date|
      if is_repeated_day(date)
        new_act = self.dup
        new_act.show_date = date
        if period != NO_EXPIRATION
          new_act.expiration_date = 
            date.advance(:days => period)
        end
        new_act.parent_id = nil
        new_act.save!
        self.repititions << new_act
      end
    end
  end

  # allows you to add rep to a rep_parent. Manually added repitition
  def add_rep(date = Date.current, period = 1)
    # must be the rep_parent
    if !self.rep_parent.nil?
      self.rep_parent.add_rep(date, period)
      return
    end

    # make sure date now or in future
    if date < Date.current
      puts "date before today"
      return
    end

    new_act = self.dup
    new_act.show_date = date
    if period != NO_EXPIRATION
      new_act.expiration_date = 
        date.advance(:days => period)
    end
    new_act.parent_id = nil
    new_act.save!
    self.repititions << new_act
    
  end
  
  # returns true if repeated act should show on that day
  def is_repeated_day(day_int)
    if day_int.is_a?(Date)
      day_int = day_int.wday
    end

    day_int = DAY_VALUES[day_int]
    act_int = repeated

    if act_int.nil? or day_int.nil?
      return false
    end

    return (act_int % day_int) == 0
    
  end

  # takes an array of wdays and sets repeated
  def set_repeated(days)
    # must pass in an array
    if days.class != Array
      puts "days must be an array"
      return nil
    end

    # convert the array values
    count = 1
    days.each do |day|
      result = DAY_VALUES[day]
      if !result.nil?
        count = count * result
      end
    end

    # set the repeated attribute
    if count != 1
      self.repeated = count
      self.save!
      return count
    else
      return nil
    end
  end
  
  # returns array corresponding to wdays
  def get_repeated
    if self.repeated.nil?
      return nil
    end

    days = Array.new
    DAY_VALUES.each do |k,v|
      if (self.repeated % v) == 0
        days << k
      end
    end

    return days
  end

  # override parent method
  # always return parent of rep_parent
  def parent
    if self.rep_parent.nil?
      if self.parent_id.nil?
        return nil
      else
        return Activity.find(self.parent_id)
      end

    else
      return self.rep_parent.parent
    end
  end
  
  # deletes reps past date
  # defults to deleting starting tomorrow
  def del_reps(start_date = Date.tomorrow)
    if start_date.is_a?(Date)
      if !self.rep_parent.nil?
        return self.rep_parent.del_reps(start_date)
      else
        self.repititions.
          where("show_date >= :date", date: start_date).
          destroy_all
      end
    end
  end

  # moves task to be on its own
  def make_root
    if self.rep_parent.nil?
      return super
    else
      return self.rep_parent.make_root
    end
  end

  # returns total payout of repititions
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
    
    # multiply complete * reward and expired * penalty
    payout = node.repititions.
      where(:state => Activity::COMPLETE).size * node.reward
    payout = payout -
      node.repititions.
      where(:state => Activity::EXPIRED).size *
      node.penalty
    return payout + child_payout
    
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
    
    # get payout of children
    count = 0 
    node.children.each do |child|
      count = count + child.week_payout(date, start_day)
    end
    
    # get reward
    act_payout = 0
    week_reps = node.repititions.
      where("completed_date >= ? AND completed_date <= ?",
            week_start, week_end)
    week_reps.each do |rep|
      if (rep.state == Activity::COMPLETE)
        act_payout = act_payout + node.reward
      end
    end
    
    # get penalty
    week_reps = node.repititions.
      where("expiration_date >= ? AND expiration_date <= ?",
            week_start, week_end)
    week_reps.each do |rep|
      if (rep.state == Activity::EXPIRED)
        act_payout = act_payout - node.penalty
      end
    end
    
    return count + act_payout
  end

  # returns the total possible reward for the period specified
  # if no period specifed then checks all reps
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

    # select correct reps
    the_reps = nil
    if start_date.nil? or end_date.nil?
      the_reps = node.repititions
    else
      the_reps = node.repititions.
        where("show_date >= ? AND show_date <= ?",
              start_date, end_date)
    end

    # return size * reward value
    return (the_reps.size * node.reward) + child_count
  end

  # returns the total possible penalty for period
  # ifno period specified then checks all reps
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

    # select correct reps
    the_reps = nil
    if start_date.nil? or end_date.nil?
      the_reps = node.repititions
    else
      the_reps = node.repititions.
        where("expiration_date >= ? AND expiration_date <= ?",
              start_date, end_date)
    end

    # return size * penalty value
    return (the_reps.size * node.penalty) + child_count
  end
  
  # deletes the rep_parent, all the reps, and children
  def remove_act
    # select rep_parent if it exists
    node = self
    if !self.rep_parent.nil?
      node = self.rep_parent
    end

    # outdent children in case remove_act doesn't delete
    node.children.each do |child|
      child.outdent
      child.remove_act
    end

    # hold parent in case it need be updated
    old_parent = node.parent
    
    node.repititions.destroy_all
    node.destroy

    if !old_parent.nil?
      old_parent.is_complete?
    end
  end

  # marks complete if child or marks rep of the day
  # updates count of rep parent
  # does not impact children
  def complete
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
      self.rep_parent.count = self.rep_parent.count + 1
      self.rep_parent.save!
    end
  end

  # marks incomplete if child or marks reps of day
  # updates count of rep_parent
  # does not impact children
  def incomplete
    # check if an individual rep, complete reps of day if not
    if self.rep_parent.nil?
      self.repititions.
        where(:show_date => Date.current).each do |rep|
        rep.incomplete
      end
      return
    end

    if self.state == Activity::COMPLETE
      # only set as incomplete if before expiration
      if self.expiration_date.nil? or 
          self.expiration_date >= Date.current 
        self.state = Activity::INCOMPLETE
      else
        self.state = Activity::EXPIRED
      end
      self.completed_date = nil
      self.save!
      self.rep_parent.count = self.rep_parent.count - 1
      self.rep_parent.save!
    end
  end

  # if a rep parent returns the children
  # if a rep returns the child activities with the same date
  def children
    if self.rep_parent.nil?
      return super
    else
      the_children = Array.new
      self.rep_parent.children.each do |child|
        if child.is_a?(Repeatable)
          
          child.repititions.
            where(:show_date => self.show_date).each do |r|
            the_children << r
          end
        elsif child.show_date == self.show_date
          the_children << child
        end
      end
      return the_children
    end
  end

  # add child to the rep_parent
  def add_child(child)
    if child.is_a? Activity
      if self.rep_parent.nil?
        return child.set_parent(self)
      else
        return child.set_parent(self.rep_parent)
      end
    else 
      puts "Child not added: child must be an activity"
      return false
    end
  end

  # sets parent of the rep_parent
  def set_parent(new_parent)
    if new_parent.is_a? Activity
      old_parent = self.parent
      if !self.rep_parent.nil?
        return self.rep_parent.set_parent(new_parent)
      end
      new_parent.children << self # add to children
      self.parent_id = new_parent.id
      self.is_root = false
      self.save!
      new_parent.is_complete?
      
      if old_parent != nil
        old_parent.children.delete(self)# delete from old parent
        old_parent.is_complete? # in case depends on 
      end
      return true
    else
      return false
    end
  end
  
end
