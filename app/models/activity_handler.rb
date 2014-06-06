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
      case params[:habit_type]
      when 'none'
        return ActivityHelper.create_activity(HABIT, params)
      when 'number'
        return ActivityHelper.create_activity(HABIT_NUMBER, params)
      when 'week'
        return ActivityHelper.create_activity(HABIT_WEEK, params)
      else
        Rails.logger.debug "invalid habit type"
        return { :habit_type => "invalid habit type" }
      end
        
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
      case params[:habit_type]
      when 'none'
        return ActivityHelper.form_errors(HABIT, params)
      when 'number'
        return ActivityHelper.form_errors(HABIT_NUMBER, params)
      when 'week'
        return ActivityHelper.form_errors(HABIT_WEEK, params)
      else
        Rails.logger.debug "invalid habit type"
        return { :habit_type => "invalid habit type" }
      end
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
    return Activity.where("(state is ? OR state is ?) AND rep_parent_id is ?",
                                 Activity::INCOMPLETE, Activity::OVERDUE, nil)
  end

  def it_and_children(id)
    it_children = [ ] 
    it_children << (id)
    Activity.find(id).children.each{ |child| it_children << it_and_children(child.id) }
    return it_children
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
      where("state is ? AND show_date is ?", 
            Activity::COMPLETE, Date.current)
    today[:incomplete] = Activity.
      where("state is ? AND show_date is ?", 
            Activity::INCOMPLETE, Date.current)
    today[:overdue] = Activity.
      where("state is ?", 
            Activity::OVERDUE)
    return today
  end

  def update_act(params)
    children = Activity.find(params[:id]).children
    Activity.find(params[:id]).destroy
    new_act_id = create_activity(params)[:new_act].id
    children.each do |child|
      child.parent_id = new_act_id
      child.save!
    end
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

  def roots(all = false)
    if all
      return Activity.where("rep_parent_id is ? AND is_root is ?", nil, true)
    else 
      return Activity.where("rep_parent_id is ? AND (state is ? OR state is ?) AND is_root is ?",
                            nil, Activity::INCOMPLETE, Activity::OVERDUE, true)
    end
  end

  def get_attributes(params)
    act = Activity.find(params[:id])
    if act.class == FullTask or act.class == PartialTask
      values = act.attributes.symbolize_keys
      values[:type_group] = 1
      return values 
    elsif act.class == Habit
      values = act.attributes.symbolize_keys 
      values[:habit_type] = 'none'
      values[:repeated] = act.get_repeated.collect { |d| d.to_s }
      values[:type_group] = 2
      return values
    elsif act.class == HabitNumber
      values = act.attributes.symbolize_keys 
      values[:habit_type] = 'number'
      values[:repeated] = act.get_repeated.collect { |d| d.to_s }
      values[:total] = act.count_goal
      values[:type_group] = 2
      return values
    elsif act.class == HabitWeek
      values = act.attributes.symbolize_keys 
      values[:habit_type] = 'week'
      values[:repeated] = act.get_repeated.collect { |d| d.to_s }
      values[:per_week] = act.count
      if !act.is_infinite?
        values[:weeks] = act.weeks_needed
      end
      values[:type_group] = 2
      return values
    end
  end
end
