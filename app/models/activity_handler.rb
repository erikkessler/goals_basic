# This class bridges the Activity framework to the user

class ActivityHandler < ActiveRecord::Base
  include MyModules

  FULL_TASK = 0
  PARTIAL_TASK = 1
  HABIT = 2
  HABIT_NUMBER = 3
  HABIT_WEEK = 4
  GOAL = 5
  PROGRESS_SUM = 6
  PROGRESS_AVG = 7
  PROGRESS_MAX = 8
  
  def create_activity(params)
    type_group_id = params[:type_group]
    case TypeGroup.find(type_group_id).name
    when 'Basic Task'
      if params[:internal] == 1.to_s 
        return ActivityHelper.create_activity(FULL_TASK, params)
      else
        return ActivityHelper.create_activity(PARTIAL_TASK, params)
      end
    when 'Habit'
      # incomplete
      Rails.logger.debug "Habit creation not yet complete"
    when 'Goal'
      # incomplete
      Rails.logger.debug "Goal creation not yet complete"
    else
      Rails.logger.debug "Invalid TypeGroup"
      return false
    end
  end

end
