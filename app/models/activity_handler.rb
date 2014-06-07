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
    act_type = activity_type(params)
    return ActivityHelper.create_activity(act_type, params)

  end

  def check_form_errors(params)
    act_type = activity_type(params)
    return ActivityHelper.form_errors(act_type, params)
  end

  def activity_type(params)
    type_group_id = params[:type_group]
    case TypeGroup.find(type_group_id).name
    when 'Basic Task'
      if params[:internal] == 1.to_s 
        return FULL_TASK
      else
        return PARTIAL_TASK
      end
    when 'Habit'
      case params[:habit_type]
      when 'none'
        return HABIT
      when 'number'
        return HABIT_NUMBER
      when 'week'
        return HABIT_WEEK
      else
        Rails.logger.debug "invalid habit type"
        return nil
      end
    when 'Goal'
      # incomplete
      Rails.logger.debug "Goal creation not yet complete"
      return nil
    else
      Rails.logger.debug "Invalid TypeGroup"
      return nil
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
    old_act = Activity.find(prams[:id])
    old_attributes = old_act.attributes.symbolize_keys
    new_type = is_diff_type(params, old_act.class)
    if new_type == false
      update_act_helper(old_act, params)
    elsif old_act.class == Habit 
      or old_act.class == HabitNumber or old_act.class == HabitWeek
      old_act = old_act.get_rep_parent
      old_act.repititions.destroy_all
      change_type_helper(old_act, nil, params)
    else
      update_act_helper(old_act, new_type, params)
    end
      

=begin
    children = Activity.find(params[:id]).children
    Activity.find(params[:id]).destroy
    new_act_id = create_activity(params)[:new_act].id
    children.each do |child|
      child.parent_id = new_act_id
      child.save!
    end
=end
  end

  def is_diff_type(params, old_type)
    new_type = activtiy_type(params)
    if old_type == FullTask and new_type != FULL_TASK
      return new_type
    elsif old_type == PartialTask and new_type != PARTIAL_TASK
      return new_type
    elsif old_type == Habit and new_type != HABIT
      return new_type
    elsif old_type == HabitNumber and new_type != HABIT_NUMBER
      return new_type
    elsif old_type == HabitWeek and new_type != HABIT_WEEK
      return new_type
    else
      return false
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
