# This type of Activity is complete iff all its chilren are complete.
# If no children just returns if its state is COMPLETE

class FullTask < Activity
  
  # if children complete iff all children are
  def is_complete? 
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
  end

end
