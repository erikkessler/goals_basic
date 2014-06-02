# This type of progress goal is complete when average >= goal
# Count stores both the number of entries and the total.
# Show date is the date the average has to be held until. 
# Expiration date is the date that can no longer lower average

class AvgUpProgress < ProgressGoal

  # max number of entries
  MAX = 100000

  # record the value to count, check if complete
  def record(value)
    self.count += ((value * MAX) + 1)
    self.save!
    self.is_complete?
  end

  # if a goal tracker gets edited
  def edit(diff, value)
    self.count += (diff * MAX)
    self.save!
    self.is_complete?
  end

  # is count <= count_goal?
  def is_complete?
    if self.show_date.nil? or self.show_date <= Date.current
      # if complete check that still valid
      if self.state == Activity::COMPLETE
        if self.average < self.count_goal
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
        if self.average >= self.count_goal
          self.state = Activity::COMPLETE
          self.completed_date = DateTime.current
          self.save!
          return true

        else
          return false
        end
      end
    else
      return false
    end
  end

  # returns the number of entries
  def get_entry_count
    return (self.count % MAX)
  end
  
  # returns the total count
  def get_total_count
    return (self.count / MAX)
  end
  
  # reuturns the average
  # can specify number of decimal places
  def average(decimal_places = nil)
    if decimal_places.nil?
      return (count / MAX)/(count % MAX).to_f
    else
      return ((count / MAX)/(count % MAX).to_f).round(decimal_places)
    end
  end
end
