class Activity < ActiveRecord::Base

  # validations
  validates :name, presence: true
  validates :state, :inclusion => {:in => 0..4}

  # allows activities to have tree like structure
  has_many :children, class_name: "Activity",
    foreign_key: "parent_id"
  belongs_to :parent, class_name: "Activity", foreign_key: "parent_id"

  # inheritance
  self.inheritance_column = :type
  scope :full_tasks, -> { where(type:'FullTask') }
  scope :partial_tasks, -> { where(type:'PartialTask') }

  # constants for state 
  INCOMPLETE = 0
  COMPLETE = 1
  OVERDUE = 2
  ABANDONED = 3
  ARCHIVED_HABIT = 4

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
      old_parent.children.delete(self)
      old_parent.is_complete?
      self.parent = nil
      self.is_root = true
      self.save!
      return true
    end
  end

  # complete it and all children
  def complete
    if self.state != COMPLETE
      self.state = COMPLETE
      self.completed_date = DateTime.now
      self.save!
    end
    self.children.each do |child| 
      child.complete
    end
    if !parent.nil?
      parent.is_complete? 
    end
  end

  # mark it and all children as incomplete
  def incomplete
    self.state = INCOMPLETE
    self.completed_date = nil
    self.save!
    self.children.each do |child|
      child.incomplete
    end
    if !parent.nil?
      parent.is_complete?
    end
  end
  
  # total payout - reward - penalty
  def total_payout
    count = 0
    self.children.each do |child|
      count = count + child.total_payout
    end
    
    if self.state == COMPLETE
      return count + self.reward
    elsif self.state == OVERDUE
      return count - self.penalty
    else 
      return count
    end
  end

  # calculates payout for the specified week
  def week_payout(date = Date.today)
    if !date.is_a? Date
      puts "Must pass in a date"
      return
    end

    week_start = date.advance(:weeks => -2).next_week(:sunday)
    week_end = date.advance(:weeks => -1).next_week(:saturday)
    date_range = week_start..week_end

    count = 0 
    self.children.each do |child|
      count = count + child.week_payout
    end
    
    act_payout = 0
    if (self.state == COMPLETE and date_range.include? self.completed_date.to_date)
      act_payout = self.reward
      
    elsif (self.state == OVERDUE and date_range.include? self.expiration_date.to_date)
      act_payout = -1 * self.penalty
    end

    return count + act_payout
  end

  # removes activity and calls remove on children
  def remove_act
    self.children.each do |child|
      child.outdent
      child.remove_act
    end
    
    self.destroy
    
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
  def total_reward
    count = 0 
    self.children.each do |child|
      count = count + child.total_reward
    end
    return self.reward + count
  end

  # returns total possible penalty
  def total_penalty
    count = 0
    self.children.each do |child|
      count = count + child.total_penalty
    end
    return self.penalty + count
  end

  # prints the tree
  def print_tree(level = 0)
    puts " " * level + self.name + "\n"
    self.children.each do |child|
      child.print_tree(level + 1)
    end
    
  end

  protected
  # removes association to old parent and adds new one
  def set_parent(new_parent)
    if new_parent.is_a? Activity
      old_parent = self.parent
      new_parent.children << self
      self.parent = new_parent
      self.is_root = false
      self.save!
      parent.is_complete?
      
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
