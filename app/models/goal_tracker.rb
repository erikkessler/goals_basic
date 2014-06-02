# This class is a special type of repeatable that is used by Goals to 
# track progress to a goal.
# </br>Hold value of check-in in count

class GoalTracker < Repeatable

  # Records the value of the checkin that is passed in through value.
  # Stores in count and makes state complete
  def complete(value = nil)
    if value.nil?
      return
    end

    # check if an individual rep, complete reps of day if not
    if self.rep_parent.nil?
      self.repititions.
        where(:show_date => Date.current).each do |rep|
        rep.complete(value)
      end
      return
    end

    if self.state == Activity::COMPLETE
      diff = value - self.count
      self.completed_date = DateTime.current
      self.count = value
      self.save!
      self.parent.edit(diff, value)
      return
    else
      self.completed_date = DateTime.current
      self.state = Activity::COMPLETE
      self.count = value
      self.save!
      self.parent.record(value)
    end
  end

  # incomplete shouldn't do anything
  def incomplete
    puts "not a feature of GoalTracker"
  end

  # returns if data has been sent
  def is_complete?
    # check if an individual rep, complete reps of day if not
    if self.rep_parent.nil?
      self.repititions.
        where(:show_date => Date.current).each do |rep|
        if !rep.is_complete?
          return false
        end
      end
      return true

    else
      return self.state == Activity::COMPLETE
    end
  end
end

