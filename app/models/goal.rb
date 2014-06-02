# Basic goal object that will be extended to support specific types of goals

class Goal < Activity

  # make sure has a goal type
  validates :goal_type, :inclusion => {:in => 0..6 }

   # inheritance
  self.inheritance_column = :type
  scope :progress_goals, -> { where(type:'ProgressGoal') }

  LT_EXTERNAL = 0 # long term, external - doesn't depend on children
  LT_INTERNAL = 1 # long term, internal - depends on children
  ST_EXTERNAL = 2 # short term
  ST_INTERNAL = 3
  WK_EXTERNAL = 4 # weekly
  WK_INTERNAL = 5 
  PROGRESS    = 6 # progress goal

  # see for testing if an internal or external goal
  def is_internal?
    return (self.goal_type % 2) == 1
  end

  # if internal then checks all children, if external then returns state
  def is_complete?
    if is_internal?
      old_state= self.state # hold old state to see if changed

      if self.children.empty?
        return self.state == Activity::COMPLETE # no children
      else
        self.children.each do |child|
          if !child.is_complete?
            if self.expiration_date.nil? or 
                self.expiration_date >= Date.current
              self.state = Activity::INCOMPLETE
            else
              self.state = Activity::EXPIRED
            end
            self.completed_date = nil
            self.save!
            if !self.parent.nil? and old_state != self.state
              self.parent.is_complete?
            end
            return false
          end
        end

        if self.state != Activity::COMPLETE
          self.state = Activity::COMPLETE
          self.completed_date = DateTime.current
          if !self.parent.nil?
            self.parent.is_complete?
          end
          self.save!
        end
        return true
      end
    else
      return self.state == Activity::COMPLETE
    end
  end

  # sets goal to ABANDONED and calls remove on children
  def remove_act
    # outdent children in case remove_act doesn't delete
    self.children.each do |child|
      child.outdent
      child.remove_act
    end
    
    # check if parent should update completeness
    old_parent = self.parent

    self.state = Activity::ABANDONED
    
    # refresh parent completeness
    if !old_parent.nil?
      old_parent.is_complete?
    end
  end

end
