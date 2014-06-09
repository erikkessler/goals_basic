# This class bridges the Activity framework to the user. Each user has one activity handler.

class ActivityHandler < ActiveRecord::Base
  include MyModules, SessionsHelper

  # Constants that define type_id
  FULL_TASK = 0
  PARTIAL_TASK = 1
  HABIT = 2
  HABIT_NUMBER = 3
  HABIT_WEEK = 4
  GOAL = 5
  PROGRESS_SUM = 6
  PROGRESS_AVG = 7
  PROGRESS_MAX = 8

  # Uses the module to create the activity
  def create_activity(params, current_user)
    act_type = activity_type(params) # gets what type of activity it is
    return ActivityHelper.create_activity(act_type, params, current_user)

  end

  # Uses the module to check for errors
  def check_form_errors(params, update = false)
    params[:habit_type] = 'none'
    act_type = activity_type(params)
    return ActivityHelper.form_errors(act_type, params, update)
  end

  # Determines what type of activity it should be based on the params
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

  # Gets activities that can be parents - incomplete or overdue
  def get_parentable(current_user)
    return current_user.activities.where("(state is ? OR state is ?) AND rep_parent_id is ?",
                                 Activity::INCOMPLETE, Activity::OVERDUE, nil)
  end

  # Takes an id and returns an array of activity ids that are the id or are children.
  # This is to ensure, when editing, an activity isn't its own parent
  def it_and_children(id, current_user)
    it_children = [ ] 
    it_children << (id)
    act = current_user.activities.find(id)
    act.children.each{ |child| it_children << it_and_children(child.id) }
    act.rep_parent_id.nil? ? nil : it_children << act.rep_parent_id
    return it_children
  end

  # Toggles the state of the activity. If it is complete, calls incomplete, if incomplete or
  # overdue calls complete
  def toggle(id, current_user)
    activity = current_user.activities.find(id)
    state = activity.state
    if state == Activity::COMPLETE
      activity.incomplete
      return "Set #{activity.name} to incomplete..."
    elsif state == Activity::INCOMPLETE or Activity::OVERDUE
      activity.complete
      return "Completed #{activity.name}!"
    end
  end

  # Gets activities that should be shown today - complete, incomplete, and overdue
  def get_today(current_user)
    today = { }
    today[:complete] = current_user.activities.
      where("state is ? AND show_date is ?", 
            Activity::COMPLETE, Date.current)
    today[:incomplete] = current_user.activities.
      where("state is ? AND show_date is ?", 
            Activity::INCOMPLETE, Date.current)
    today[:overdue] = current_user.activities.
      where("state is ?", 
            Activity::OVERDUE)
    return today
  end

  # Updates the activity based on what type it is
  def update_act(params, current_user)
    old_act = current_user.activities.find(params[:id])
    
    # tasks
    if old_act.class == FullTask or old_act.class == PartialTask
      # set the name, desc, show_date, expiration_date, reward, and penalty
      old_act.name = params[:name]
      old_act.description = params[:description]
      old_act.show_date = params[:show_date]
      old_act.expiration_date = params[:expiration_date]
      old_act.reward = params[:reward]
      old_act.penalty = params[:penalty]
      old_act.save!
      
      # if parent changed, makes sure it a valid change and change it
      parent_id = params[:parent_id].to_i
      if !params[:parent_id].empty? and parent_id != old_act.parent_id
            handler = current_user.activity_handler
            it_and_child = handler.it_and_children(old_act.id)
            if !it_and_child.include?(parent_id)
              parent = current_user.activities.find(parent_id)
              parent.add_child(old_act)
            end
      end

    # habits
    elsif old_act.class == Habit or old_act.class == HabitNumber or 
        old_act.class == HabitWeek
      
      # if not a rep_parent then don't need to change expiration_date of the whole habit
      expire = true
      if !old_act.rep_parent.nil?
        old_act.show_date = params[:show_date]
        old_act.expiration_date = params[:expiration_date]
        old_act.save!
        old_act = old_act.rep_parent
        expire = false
      end


      # change the name, desc, reward, penalty
      old_act.name = params[:name]
      old_act.description = params[:description]
      old_act.reward = params[:reward]
      old_act.penalty = params[:penalty]
      old_act.save!
      
      # change it for the reps as well
      old_act.repititions.each do |rep|
        rep.name = params[:name]
        rep.description = params[:description]
        rep.reward = params[:reward]
        rep.penalty = params[:penalty]
        rep.save!
      end

      
      # if repeated changed, delete future reps and create new ones
      gen = false
      repeated = params[:repeated].keys.to_a.collect { |d| d.to_i }
      if repeated != old_act.get_repeated
        old_act.del_reps
        old_act.set_repeated(repeated)
        gen = true
      end

      # if expiration date changed, delete future reps
      if expire and old_act.expiration_date != params[:expiration_date]
        old_act.del_reps
        old_act.expiration_date = params[:expiration_date]
        gen = true
      end

      old_act.save!
      
      # generate new reps if needed
      if gen
        if old_act.expiration_date.nil?
          handler = current_user.activity_handler
          old_act.gen_reps(Date.tomorrow, handler.upto_date)
        else
          old_act.gen_reps(Date.tomorrow, old_act.expiration_date)
        end
        old_act.reload
        old_act.repititions.each { |rep| current_user.activities << rep }
      end
      
      # if parent changed, make sure it valid and change it
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

  # calls remove_act on the activity
  def remove_act(id, current_user)
    activity = current_user.activities.find(id)
    activity.remove_act
    return "Removed #{activity.name}!"
  end

  # gets the activities that are assigned for each day of the week
  def week(date, week_begin, current_user)
    days = {}
    if date == "this_week"
      date = Date.current
    else
      begin
        date = Date.parse(date)
      rescue
        date = Date.current
      end
    end

    # get the beginning of the week
    first_date = date.
      beginning_of_week(start_date = week_begin)

    # go through each day of the week and get the activities
    for i in 0..6
      add_date= first_date.advance(:days => i)
      acts = current_user.activities.where(:show_date => add_date)
      days[add_date] = acts
    end

    return days
  end

  # Returns activities that are root. The all parameter determines whether to get all or just,
  # incomplete/overdue.
  def roots(all = false)
    if all
      return current_user.activities.where("rep_parent_id is ? AND is_root is ?", nil, true)
    else 
      return current_user.activities.where("rep_parent_id is ? AND (state is ? OR state is ?) AND is_root is ?",
                            nil, Activity::INCOMPLETE, Activity::OVERDUE, true)
    end
  end

  # Gets the attributes of a certain activity and puts them in a format that allows the 
  # forms to preset their data when editing an activity
  def get_attributes(params, current_user)
    act = current_user.activities.find(params[:id]) # get the activity

    # Check what type it is
    if act.class == FullTask or act.class == PartialTask
      values = act.attributes.symbolize_keys # make the stings symbols
      values[:type_group] = 1
      return values 

    elsif act.class == Habit
      values = act.attributes.symbolize_keys 
      values[:habit_type] = 'none' # set the habit type
      
      # get the repeated values
      repeated = {}
      act.get_repeated.each { |d| repeated[d.to_s] = d.to_s }
      values[:repeated] = repeated
      values[:type_group] = 2

      # check if dealing with a repitition of the rep_parent
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

      # get the repeated values
      repeated = {}
      act.get_repeated.each { |d| repeated[d.to_s] = d.to_s }
      values[:repeated] = repeated
      values[:total] = act.count_goal
      values[:type_group] = 2

      # check if dealing with a repitition of the rep_parent
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

      repeated = {}
      act.get_repeated.each { |d| repeated[d.to_s] = d.to_s }
      values[:repeated] = repeated
      values[:type_group] = 2

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
      
      return values
    end
  end

  # Gets the payout for the week of a certain activity
  def get_week_reward(act, date, start = :monday)
    return act.week_payout(date, start)

  end
end
