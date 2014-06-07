module MyModules
  
  # This module hold methods for the ActivityHelper to use
  module ActivityHelper
    
    # Creates an acitvity of the correct type
    def self.create_activity(type_id, params)
      # switch on type_id
      case type_id

      when ActivityHandler::FULL_TASK 
        return task_creator(type_id, params)
      when ActivityHandler::PARTIAL_TASK
        return task_creator(type_id, params)
      when ActivityHandler::HABIT
        return habit_creator(type_id, params)
      when ActivityHandler::HABIT_NUMBER
        return habit_creator(type_id, params)
      when ActivityHandler::HABIT_WEEK
        return habit_creator(type_id, params)
      else
        Rails.logger.debug "Invalid type_id"
        return { :type_id => "invalid type_id" }
      end
    end

    def self.task_creator(type_id, params)
      errors = form_errors(type_id, params)

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
      if !parent_id.empty? and parent_id != new_activity.id
        parent = Activity.find(parent_id)
        parent.add_child(new_activity)
      end

      return errors

    end

    def self.habit_creator(type_id, params)
      errors = form_errors(type_id, params)
      
      if !errors.empty?
        return errors
      end
      
      new_activity = nil
      period = params[:period]
      if period.empty?
        period = Repeatable::NO_EXPIRATION
      else
        period = period.to_i
      end
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
      if !parent_id.empty? and parent_id != new_activity.id
        parent = Activity.find(parent_id)
        parent.add_child(new_activity)
      end

      repeated = params[:repeated]
      repeated = repeated.collect { |i| i.to_i }
      new_activity.set_repeated(repeated)
      new_activity.reload
      
      if params[:expiration_date].empty?
        handler = ActivityHandler.find(1)
        new_activity.gen_reps(Date.current, handler.upto_date, period)
      else
        new_activity.gen_reps(Date.current, Date.parse(params[:expiration_date]), period)
      end

      return errors
    end
    
    def self.update_act_helper(old_act, new_act_type, params)
      if new_act_type.nil?
        if old_act.class == FullTask or old_act.class == PartialTask
          old_act.name = params[:name] 
          old_act.show_date = params[:show_date] 
          old_act.description = params[:description]
          old_act.expiration_date = params[:expiration_date]
          old_act.reward = params[:reward]
          old_act.penalty = params[:penalty]
          
          set_parent(old_act, params[:parent_id].to_i)
          
        elsif old_act.class == Habit 
          habit_edit(params, old_act)

        elsif old_act.class == HabitNumber
          habit_edit(params, old_act)
          old_act.total = params[:total]
        elsif old_act.class == HabitWeek
          habit_edit(params, old_act)
          
        end
      end
    end
    
    def habit_edit(params, old_act)
      
      old_act.name = params[:name]  
      old_act.description = params[:description]
      old_act.expiration_date = params[:expiration_date]
      old_act.reward = params[:reward]
      old_act.penalty = params[:penalty]
      
      set_parent(old_act, params[:parent_id].to_i)

      gen = false
      repeated = params[:repeated].collect { |d| d.to_i }
      if repeated != old_act.get_repeated
        old_act.del_reps
        old_act.set_repeated(repeated)
        gen = true
      end

      if old_act.expiration_date != params[:expiration_date]
        odl_act.del_reps
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

    def self.set_parent(act, parent_id)
      if parent_id != act.parent_id
            handler = ActivityHandler.find(0)
            it_and_child = handler.it_and_children(act.id)
            if !it_and_child.include?(parent_id)
              parent = Activity.find(parent_id
              parent.add_child(act)
            end
          end
    end
    

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

    def self.form_errors(type_id, params)
      if type_id == ActivityHandler::FULL_TASK or
          type_id == ActivityHandler::PARTIAL_TASK
        errors = basic_errors(params)

        
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
            (Date.parse(params[:expiration_date]) < Date.parse(params[:show_date]))
            Rails.logger.debug "Expiration date before show"
            errors[:expiration_date] = "Expiration date can't be before date of task"
          rescue
            Rails.logger.debug "Invalid expiration_date format"
            errors[:expiration_date] = "Invalid date for expiration date"
          end
        end

        

        return errors

      elsif type_id == ActivityHandler::HABIT or
          type_id == ActivityHandler::HABIT_NUMBER or
          type_id == ActivityHandler::HABIT_WEEK
        errors = basic_errors(params)

        # ensure at least one repeated day
        if params[:repeated].nil?
          Rails.logger.debug "No repeated days"
          errors[:repeated] = "Must repeat at least one day of week"
        end

        # ensure period valid
        if !params[:period].empty? and params[:period].to_i <= 0
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

        # if habit number need a total
        if type_id == ActivityHandler::HABIT_NUMBER
          if params[:total].empty?
            Rails.logger.debug "Need a total number of completions"
            errors[:expiration_date] = "Must specify required number of completions"
          elsif params[:total].to_i <= 0
            Rails.logger.debug "Total needed not positive"
            errors[:expiration_date] = "Total completions required must be positive"
          end
        end

        # if habit week need per week 
        if type_id == ActivityHandler::HABIT_WEEK
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
