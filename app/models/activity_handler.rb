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

  def check_form_errors(params)
    type_group_id = params[:type_group]
    case TypeGroup.find(type_group_id).name
    when 'Basic Task'
      if params[:internal] == 1.to_s 
        return ActivityHelper.form_errors(FULL_TASK, params)
      else
        return ActivityHelper.form_errors(PARTIAL_TASK, params)
      end
    when 'Habit'
      # incomplete
      Rails.logger.debug "Habit creation not yet complete"
      return {}
    when 'Goal'
      # incomplete
      Rails.logger.debug "Goal creation not yet complete"
      return {}
    else
      Rails.logger.debug "Invalid TypeGroup"
      return {}
    end
  end

  def get_parentable
    return Activity.where("state is ? OR state is ? AND rep_parent_id is ?",
                                 Activity::INCOMPLETE, Activity::OVERDUE, nil)
  end

  def toggle(id)
    activity = Activity.find(id)
    state = activity.state
    if state == Activity::COMPLETE
      activity.incomplete
      return "Set #{activity.name} to incomplete..."
    elsif state == Activity::INCOMPLETE or Activity::OVERDUE
      activity.complete
      return "Completed #{activity.name}!"
    end
  end

  def get_today
    today = { }
    today[:complete] = Activity.
      where("state is ? AND rep_parent_id is ? AND show_date is ?", 
            Activity::COMPLETE, nil, Date.current)
    today[:incomplete] = Activity.
      where("state is ? AND rep_parent_id is ? AND show_date is ?", 
            Activity::INCOMPLETE, nil, Date.current)
    today[:overdue] = Activity.
      where("state is ? AND rep_parent_id is ?", 
            Activity::OVERDUE, nil)
    return today
  end

  def remove_act(id)
    activity = Activity.find(id)
    activity.remove_act
    return "Removed #{activity.name}!"
  end

  def week(date, week_begin)
    days = {}
    if date == "this_week"
      date = Date.current
    else
      date = Date.parse(date)
    end

    first_date = date.
      beginning_of_week(start_date = week_begin)

    for i in 0..6
      add_date= first_date.advance(:days => i)
      acts = Activity.where(:show_date => add_date)
      days[add_date] = acts
    end

    return days
  end
end
