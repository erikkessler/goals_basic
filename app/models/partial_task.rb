# This type of activity is completly isolated from its children in terms
# of being complete

class PartialTask < Activity
  
  # returns state of task in isolation
  def is_complete?
    return self.state == Activity::COMPLETE
  end

  # marks the task and only the task as complete
  def complete
    if self.state != Activity::COMPLETE
      self.state = Activity::COMPLETE
      self.completed_date = DateTime.current
      self.save!

      if self.parent != nil
        self.parent.is_complete?
      end
    end
  end
  
  # marks the task and only the task as incomplete
  def incomplete
    if self.state != Activity::INCOMPLETE and self.state != Activity::EXPIRED
      if self.expiration_date.nil? or 
          self.expiration_date >= Date.current
        self.state = Activity::INCOMPLETE
      else
        self.state = Activity::EXPIRED
      end
      self.completed_date = nil
      self.save!

      if self.parent != nil
        self.parent.is_complete?
      end
    end
  end
end
