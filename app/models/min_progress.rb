# This type of progress goal is complete when you reach a specified minmum.
# </br>Example: Run a 6:45 mi

class MinProgress < ProgressGoal

  # record the value to count, check if complete
  def record(value)
    if value < self.count
      self.count = value 
      self.save!
      self.is_complete?
    end
  end

  # if a goal tracker gets edited
  def edit(diff, value)
    self.record(value)
  end

  # is count <= count_goal?
  def is_complete?
    # if complete check that still valid
    if self.state == Activity::COMPLETE
      if self.count > self.count_goal
        if self.expiration_date.nil? or 
            self.expiration_date >= Date.current
          self.state = Activity::INCOMPLETE
        else
          self.state = Activity::EXPIRED
        end
        self.completed_date = nil
        self.save!
        return false
      else
        return true # state did not change - still complete
      end
    else
      # not complete, is it now?
      if self.count <= self.count_goal
        self.state = Activity::COMPLETE
        self.completed_date = DateTime.current
        self.save!
        return true

      else
        return false
      end
    end

  end

  
end
