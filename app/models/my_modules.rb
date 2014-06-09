module MyModules
  
  # This module hold methods for the ActivityHelper to use
  module ActivityHelper
    
    # Creates an acitvity of the correct type
    def self.create_activity(type_id, params, current_user)
      # switch on type_id
      case type_id

      when ActivityHandler::FULL_TASK 
        return task_creator(type_id, params, current_user)
      when ActivityHandler::PARTIAL_TASK
        return task_creator(type_id, params, current_user)
      when ActivityHandler::HABIT
        return habit_creator(type_id, params, current_user)
      when ActivityHandler::HABIT_NUMBER
        return habit_creator(type_id, params, current_user)
      when ActivityHandler::HABIT_WEEK
        return habit_creator(type_id, params, current_user)
      else
        Rails.logger.debug "Invalid type_id"
        return { :type_id => "invalid type_id" }
      end
    end

    # Creates a new task of the given type
    def self.task_creator(type_id, params)
      errors = form_errors(type_id, params) # get any errors

      # return the errors if there are any
      if !errors.empty?
        return errors
      end

      # create the new task
      new_activity = nil
      if type_id == ActivityHandler::FULL_TASK
        new_activity = FullTask.create(name: params[:name], 
                                       show_date: params[:show_date], 
                                       description: params[:description],
                                       expiration_date: params[:expiration_date],
                                       reward: params[:reward],
                                       penalty: params[:penalty])
      elsif type_id == ActivityHandler::PARTIAL_TASK
        new_activity = PartialTask.create(name: params[:name], 
                                          show_date: params[:show_date], 
                                          description: params[:description],
                                          expiration_date: params[:expiration_date],
                                          reward: params[:reward],
                                          penalty: params[:penalty])
      end

      errors[:new_act] = new_activity

      # if it has a parent, add activity to it
      parent_id = params[:parent_id].to_i
      if !params[:parent_id].empty? and parent_id != new_activity.id
        parent = Activity.find(parent_id)
        parent.add_child(new_activity)
      end

      # add activity to the user
      current_user.activities << new_activity

      return errors

    end

    # Creates a habit of the given type
    def self.habit_creator(type_id, params, current_user)
      errors = form_errors(type_id, params) # get any errors
      
      # return the errors if there are any
      if !errors.empty?
        return errors
      end
      
      # determine what the period is
      period = params[:period]
      if period.empty?
        period = Repeatable::NO_EXPIRATION
      else
        period = period.to_i
      end

      # create the new habit
      new_activity = nil
      if type_id == ActivityHandler::HABIT
        new_activity = Habit.create(name: params[:name],
                                    description: params[:description],
                                    expiration_date: params[:expiration_date],
                                    reward: params[:reward],
                                    penalty: params[:penalty],
                                    period: period)
                                    
      elsif type_id == ActivtiyHandler::HABIT_NUMBER
        new_activity = HabitNumber.create(name: params[:name],
                                          description: params[:description],
                                          expiration_date: params[:expiration_date],
                                          reward: params[:reward],
                                          penalty: params[:penalty],
                                          period: period,
                                          count_goal: params[:total])
      elsif type_id == ActivityHadler::HABIT_WEEK
        weeks = params[:weeks]
        if weeks.empty?
          weeks = HabitWeek::INFINITE_WEEKS
        end
        new_activity = HabitWeek.create(name: params[:name],
                                        description: params[:description],
                                        expiration_date: params[:expiration_date],
                                        reward: params[:reward],
                                        penalty: params[:penalty],
                                        period: period,
                                        count: params[:per_week])
        new_activity.set_weeks(weeks)
      end

      errors[:new_act] = new_activity

      # if it has a parent, add activity to it
      parent_id = params[:parent_id].to_i
      if !params[:parent_id].empty? and parent_id != new_activity.id
        parent = Activity.find(parent_id)
        parent.add_child(new_activity)
      end

      # set repeated
      repeated = params[:repeated]
      repeated = repeated.keys.to_a.collect { |i| i.to_i }
      new_activity.set_repeated(repeated)
      new_activity.reload
      
      # generate reps based on the expiration date. Is no expiration date gen upto the
      # date defined in the ActivityHandler
      if params[:expiration_date].empty?
        handler = current_user.activity_handler
        new_activity.gen_reps(Date.current, handler.upto_date, period)
      else
        new_activity.gen_reps(Date.current, Date.parse(params[:expiration_date]), period)
      end

      # add the habit and all reps to the user
      current_children.activities << new_activity
      new_activity.repititions.each {|rep| current_children.activities << rep }

      return errors
    end


    # Basic errors shared by all activities - name, reward, penalty
    def self.basic_errors(params)
      errors = { }
      
      # ensure it has a name
      if params[:name].empty?
        Rails.logger.debug "No name for full task"
        errors[:name] = "Must have a name"
      end

      if !params[:reward].empty? and params[:reward].to_i < 0
        Rails.logger.debug "Reward less than 0"
        errors[:reward] = "Reward must be greater than 0"
      end

      if !params[:penalty].empty? and params[:penalty].to_i < 0
        Rails.logger.debug "Reward less than 0"
        errors[:penalty] = "Reward must be greater than 0"
      end

      return errors
    end

    # Returns the errors based on the type of activity
    # Update just specifies for the habits if certain things need to be checked
    def self.form_errors(type_id, params, update = false)
      # tasks
      if type_id == ActivityHandler::FULL_TASK or
          type_id == ActivityHandler::PARTIAL_TASK 
        errors = basic_errors(params) # get basic errors

        
        # ensure it has a show_date
        if params[:show_date].empty?
          Rails.logger.debug "No show date for full task"
          errors[:show_date] = "Must include a date to show the task on"
        else
          begin
            Date.parse(params[:show_date])
            if Date.parse(params[:show_date]) < Date.today 
              Rails.logger.debug "Show date in past"
              errors[:show_date] = "Date to show task cannot be in past"
            end
          rescue ArgumentError
            Rails.logger.debug "Invalid show_date format"
            errors[:show_date] = "Invalid date for show date"
          end
        end

        

        # make sure expiration date after show date
        if !params[:expiration_date].empty? 
          begin
            if (Date.parse(params[:expiration_date]) < Date.parse(params[:show_date]))
              Rails.logger.debug "Expiration date before show"
              errors[:expiration_date] = "Expiration date can't be before date of task"
            end
          rescue
            Rails.logger.debug "Invalid expiration_date format"
            errors[:expiration_date] = "Invalid date for expiration date"
          end
        end

        

        return errors

      # habits
      elsif type_id == ActivityHandler::HABIT or
          type_id == ActivityHandler::HABIT_NUMBER or
          type_id == ActivityHandler::HABIT_WEEK
        errors = basic_errors(params) # get basic errors

        # ensure at least one repeated day
        if params[:repeated].nil?
          Rails.logger.debug "No repeated days"
          errors[:repeated] = "Must repeat at least one day of week"
        end

        # ensure period valid
        if !update and !params[:period].empty? and params[:period].to_i <= 0 
          Rails.logger.debug "Period is invalid"
          errors[:period] = "Period must be blank (infinte) or greater than 0"
        end

        # expiration date in future
        if !params[:expiration_date].empty?
          begin
            if Date.parse(params[:expiration_date]) <= Date.current 
              Rails.logger.debug "Expiration date in past"
              errors[:expiration_date] = "Expiration date must be in future"
            end
          rescue
            Rails.logger.debug "Invalid expiration_date format"
            errors[:expiration_date] = "Invalid date for expiration date"
          end
        end

        # if HabitNumber, need a total
        if !update and type_id == ActivityHandler::HABIT_NUMBER
          if params[:total].empty?
            Rails.logger.debug "Need a total number of completions"
            errors[:expiration_date] = "Must specify required number of completions"
          elsif params[:total].to_i <= 0
            Rails.logger.debug "Total needed not positive"
            errors[:expiration_date] = "Total completions required must be positive"
          end
        end

        # if HabitWeek, need per week 
        if !update and type_id == ActivityHandler::HABIT_WEEK
          if params[:per_week].empty?
            Rails.logger.debug "Need a number of completionsper week"
            errors[:expiration_date] = "Must specify required number of completions per week"
          elsif params[:total].to_i <= 0
            Rails.logger.debug "Per week needed not positive"
            errors[:expiration_date] = "Completions per week must be positive"
          end

          if !params[:weeks].empty? and params[:weeks] <= 0
            Rails.logger.debug "Weeks is not positive"
            errors[:weeks] = "Number of weeks must be positive (or blank)"
          end
        end

        return errors
      end
    end
  end
end
