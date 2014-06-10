# An activity acts as the base object for the task manager, it is designed
# to be exended by other classes to support additional features.

class Activity < ActiveRecord::Base

  # validations
  validates :name, presence: true
  validates :state, :inclusion => {:in => 0..5}

  # allows activities to have tree like structure
  has_many :children, class_name: "Activity",
    foreign_key: "parent_id"
  belongs_to :parent, class_name: "Activity", foreign_key: "parent_id"
  has_many :permissions

  # inheritance
  self.inheritance_column = :type
  scope :full_tasks, -> { where(type:'FullTask') }
  scope :partial_tasks, -> { where(type:'PartialTask') }
  scope :repeatables, -> { where(type:'Repeatable') }
  scope :goals, -> { where(type:'Goal') }

  # constants for state 
  INCOMPLETE = 0
  COMPLETE = 1
  OVERDUE = 2
  ABANDONED = 3
  ARCHIVED_HABIT = 4
  EXPIRED = 5

  # adds a child the activity
  def add_child(child)
    if child.is_a? Activity
      return child.set_parent(self)
    else 
      puts "Child not added: child must be an activity"
      return false
    end
  end

  # returns whether or not the activity is complete
  # if any child is incomplete it returns false
  def is_complete?
    if self.state == COMPLETE
      self.children.each do |child|
        if !child.is_complete?
          return false
        end
      end
      return true

    else
      return false
    end
  end

  # move out one level
  def outdent
    old_parent = self.parent
    if old_parent.nil?
      # if no parent, it is already at highest level
      return false
    elsif  old_parent.parent.nil?
      return self.make_root
    else
      return old_parent.parent.add_child(self)
    end
  end  

  # move to root
  def make_root
    if self.is_root?
      return true
    else
      old_parent = self.parent
      old_parent.children.delete(self) # detach from parent
      old_parent.is_complete? # refresh parent completeness
      self.parent = nil
      self.is_root = true
      self.save!
      return true
    end
  end

  # set activity's state to complete and call complete on all children
  def complete
    # check that is not already complete
    if self.state != COMPLETE
      self.state = COMPLETE
      self.completed_date = DateTime.current
      self.save!
    end
    
    # call complete on each child
    self.children.each do |child| 
      child.complete
    end

    # refresh parent completeness
    if !self.parent.nil?
      self.parent.is_complete? 
    end
  end

  # set activity's state to incomplete and call on all children
  def incomplete
    if self.state != INCOMPLETE or self.state != EXPIRED
      # only set as incomplete if before expiration
      if self.expiration_date.nil? or 
          self.expiration_date >= Date.current 
        self.state = INCOMPLETE
      else
        self.state = EXPIRED
      end
      self.completed_date = nil
      self.save!

      # refresh parent's completeness
      if !parent.nil?
        parent.is_complete?
      end
    end

    # call incomplete on each child
    self.children.each do |child|
      child.incomplete
    end
  end
  
  # calculate total payout
  # if completed then the reward
  # if expired then penalty
  def total_payout
    # calculate children payout
    count = 0
    self.children.each do |child|
      count = count + child.total_payout
    end
   
    # calculate payout of this ativity
    if self.state == COMPLETE
      return count + self.reward
    elsif self.state == EXPIRED
      return count - self.penalty
    else 
      return count
    end

  end

  # calculates payout for the week of the specified date
  # start_day allows you to specify what day to start the week
  def week_payout(date = Date.current, start_day = "monday")
    if !date.is_a? Date
      puts "Must pass in a date"
      return
    end

    # calculate range of dates for the week
    week_start = date.beginning_of_week(start_date = start_day.to_sym)
    week_end =  date.end_of_week(start_date = start_day.to_sym)
    date_range = week_start..week_end

    # calculate child payout for the week
    count = 0 
    self.children.each do |child|
      count = count + child.week_payout(date, start_day)
    end
    
    # calculate payout for this activity
    act_payout = 0
    if (self.state == COMPLETE and date_range.include? self.completed_date.to_date)
      act_payout = self.reward # completed this week
      
    elsif (self.state == EXPIRED and date_range.include? self.expiration_date)
      act_payout = -1 * self.penalty # expired this week
    end

    return count + act_payout
  end

  # removes activity and calls remove on children
  def remove_act
    # outdent children in case remove_act doesn't delete
    self.children.each do |child|
      child.outdent
      child.remove_act
    end
    
    # check if parent should update completeness
    old_parent = self.parent

    self.destroy
    
    # refresh parent completeness
    if !old_parent.nil?
      old_parent.is_complete?
    end
  end

  # returns number of sub activities
  def num_children
    count = 0
    self.children.each do |child|
      count = count + child.num_children
    end

    return self.children.size + count
  end

  # returns total possible reward
  # start and end_date allow you to specify a range
  def total_reward(start_date = nil, end_date = nil)
    # count children rewards
    count = 0 
    self.children.each do |child|
      count = count + child.total_reward(start_date, end_date)
    end

    # if no range specified just return reward
    if start_date.nil? or end_date.nil?
      return self.reward + count
    else
      # else check that show_date within range
      date_range = start_date..end_date
      if date_range.include? self.show_date
        return self.reward + count
      else
        return count
      end
    end
  end

  # returns total possible penalty
  def total_penalty(start_date = nil, end_date = nil)
    #count children penalty
    count = 0
    self.children.each do |child|
      count = count + child.total_penalty(start_date, end_date)
    end

    # if no range just return penalty
    if start_date.nil? or end_date.nil?
      return self.penalty + count
    else
      # else check that expires in range
      date_range = start_date..end_date
      if date_range.include? self.expiration_date
        return self.penalty + count
      else
        return count
      end
    end
  end

  # prints the tree
  def print_tree(level = 0)
    puts " " * level + self.name + "\n"
    self.children.each do |child|
      child.print_tree(level + 1)
    end
    
  end

  # removes association to old parent and adds new one
  def set_parent(new_parent)
    if new_parent.is_a? Activity
      old_parent = self.parent
      new_parent.children << self # add to new parent
      self.parent = new_parent
      self.is_root = false
      self.save!
      new_parent.is_complete? # update new_parent completeness
      
      # remove from old parent
      if old_parent != nil
        old_parent.children.delete(self)
        old_parent.is_complete? # in case depends on 
      end
      
      return true
    else

      return false
    end
  end

end
