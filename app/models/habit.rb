# This type of repeatable is nearly idenitcal to the vanilla repeatable
# execpt that when remove_act is called on a Habit the type is set to 
# ARCHIVED_HABIT. 
# * The goal is that it is possible end a Habit while maintaining
# a record of it. 
# * A plain Habit would be used when you don't have a goal number of times that
# you want to complete the task
# * Example: Make bed every day - there is no reason to put an end date on this 
# but there may come a point where it is a habit and thus no reason to keep it

class Habit < Repeatable

  # inheritance
  self.inheritance_column = :type
  scope :numberhabits, -> { where(type:'HabitNumber') }
  scope :weekhabits, -> { where(type:'HabitWeek') }

  # Sets state to ARCHIVED_HABIT, deletes all future reps, and calls
  # remove_act on children
  def remove_act
    # select rep_parent if it exists
    node = self
    if !self.rep_parent.nil?
      return self.destroy
    end

    # outdent children in case remove_act doesn't delete
    node.children.each do |child|
      child.outdent
      child.remove_act
    end

    # hold parent in case it need be updated
    old_parent = node.parent
    
    node.del_reps
    node.state = Activity::ARCHIVED_HABIT
    node.save!

    if !old_parent.nil?
      old_parent.is_complete?
    end
  end
  
end
