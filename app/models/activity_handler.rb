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

  def check_form_errors(params, update = false)
    params[:habit_type] = 'none'
    act_type = activity_type(params)
    return ActivityHelper.form_errors(act_type, params, update)
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
    act = Activity.find(id)
    act.children.each{ |child| it_children << it_and_children(child.id) }
    act.rep_parent_id.nil? ? nil : it_children << act.rep_parent_id
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
    old_act = Activity.find(params[:id])
    
    if old_act.class == FullTask or old_act.class == PartialTask
      old_act.name = params[:name]
      old_act.description = params[:description]
      old_act.show_date = params[:show_date]
      old_act.expiration_date = params[:expiration_date]
      old_act.reward = params[:reward]
      old_act.penalty = params[:penalty]
      old_act.save!
      
      parent_id = params[:parent_id].to_i
      if !params[:parent_id].empty? and parent_id != old_act.parent_id
            handler = ActivityHandler.find(1)
            it_and_child = handler.it_and_children(old_act.id)
            if !it_and_child.include?(parent_id)
              parent = Activity.find(parent_id)
              parent.add_child(old_act)
            end
      end
    elsif old_act.class == Habit or old_act.class == HabitNumber or 
        old_act.class == HabitWeek
      
      expire = true

      if !old_act.nil?
        old_act.show_date = params[:show_date]
        old_act.expiration_date = params[:expiration_date]
        old_act.save!
        old_act = old_act.rep_parent
        expire = false
      end


      old_act.name = params[:name]
      old_act.description = params[:description]
      
      old_act.repititions.each do |rep|
        rep.name = params[:name]
        rep.description = params[:description]
        rep.reward = params[:reward]
        rep.penalty = params[:penalty]
        rep.save!
      end

      old_act.reward = params[:reward]
      old_act.penalty = params[:penalty]
      old_act.save!

      gen = false
      repeated = params[:repeated].collect { |d| d.to_i }
      if repeated != old_act.get_repeated
        old_act.del_reps
        old_act.set_repeated(repeated)
        gen = true
      end

      if expire and old_act.expiration_date != params[:expiration_date]
        old_act.del_reps
        old_act.expiration_date = params[:expiration_date]
        gen = true
      end

      old_act.save!
      
      if gen
        if old_act.expiration_date.nil?
          handler = ActivityHandler.find(0)
          old_act.gen_reps(Date.tomorrow, handler.upto_date)
        else
          old_act.gen_reps(Date.tomorrow, old_act.expiration_date)
        end
      end

      parent_id = params[:parent_id].to_i
      if params[:parent_id].empty? 
        old_act.make_root
      elsif parent_id != old_act.parent_id
            handler = ActivityHandler.find(1)
            it_and_child = handler.it_and_children(old_act.id)
            if !it_and_child.include?(parent_id)
              parent = Activity.find(parent_id)
              parent.add_child(old_act)
            end
      end
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
      if act.rep_parent.nil?
        values[:is_rp] = true
      else
        values[:is_rp] = false
        values[:parent_id] = act.rep_parent.parent_id
      end
      return values
    elsif act.class == HabitNumber
      values = act.attributes.symbolize_keys 
      values[:habit_type] = 'number'
      values[:repeated] = act.get_repeated.collect { |d| d.to_s }
      values[:total] = act.count_goal
      values[:type_group] = 2
      if act.rep_parent.nil?
        values[:is_rp] = true
      else
        values[:is_rp] = false
        values[:parent_id] = act.rep_parent.parent_id
      end
      return values
    elsif act.class == HabitWeek
      values = act.attributes.symbolize_keys 
      values[:habit_type] = 'week'
      values[:repeated] = act.get_repeated.collect { |d| d.to_s }
      values[:per_week] = act.count
      if act.rep_parent.nil?
        values[:is_rp] = true
      else
        values[:is_rp] = false
        values[:parent_id] = act.rep_parent.parent_id
      end
      if !act.is_infinite?
        values[:weeks] = act.weeks_needed
      end
      values[:type_group] = 2
      return values
    end
  end
end
