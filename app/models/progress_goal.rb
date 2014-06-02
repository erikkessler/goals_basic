# This type of goal is one where you periodically check in.
# </br>Creates a GoalTracker child that allows you to input progress

class ProgressGoal < Goal
  
  scope :tracker, -> { children.where(type:'GoalTracker')[0] }

  # does nothing now, but subclasses do stuff with it
  def record; end
  def is_complete?; end
  def complete; end
  def incomplete; end

  # calls the super method to set state to ABANDONED but also dels_reps
  def remove_act
    super
    tracker.del_reps
  end
end
