# This type of goal is one where you periodically check in.
# </br>Creates a GoalTracker child that allows you to input progress

class ProgressGoal < Goal
  
  validates :count_goal, :presence => true

  # does nothing now, but subclasses do stuff with it
  def record; end
  def is_complete?; end
  def complete; end
  def incomplete; end
  def edit(diff, value); end

  # calls the super method to set state to ABANDONED but also dels_reps
  def remove_act
    tracker.del_reps
    today = tracker.repititions.where(:show_date => Date.current, 
                                      :state => Activity::INCOMPLETE)
    today.each do |rep|
      rep.destroy
    end
    super
  end

  def tracker
    return self.children.where(type:'GoalTracker')[0]
  end
end
