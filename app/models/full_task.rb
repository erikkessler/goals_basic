class FullTask < Activity
  
  # if children complete iff all children are
  def is_complete? 
    if self.children.empty?
      return self.state == Activity::COMPLETE
    else
      self.children.each do |child|
        if !child.is_complete?
          self.state = Activity::INCOMPLETE
          self.completed_date = nil
          self.save!
          return false
        end
      end

      if self.state != Activity::COMPLETE
        self.state = Activity::COMPLETE
        self.completed_date = DateTime.current
        self.save!
      end
      return true
    end
  end

end
