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
      else
        Rails.logger.debug "Invalid type_id"
      end
    end

    def self.task_creator(type_id, params)
      errors = { }
      # ensure it has a show_date
      if params[:show_date].empty?
        Rails.logger.debug "No show date for full task"
        errors[:show_date] = "Must include a date to show the task on"
      elsif Date.parse(params[:show_date]) < Date.today # TIME ZONE PROBLEM
        Rails.logger.debug "Show date in past"
        errors[:show_date] = "Date to show task cannot be in past"
      end

      # make sure expiration date after show date
      if !params[:expiration_date].empty? and 
          (Date.parse(params[:expiration_date]) < Date.parse(params[:show_date]))
        Rails.logger.debug "Expiration date before show"
        errors[:expiration_date] = "Expiration date can't be before date of task"
      end

      # ensure it has a name
      if params[:name].empty?
        Rails.logger.debug "No name for full task"
        errors[:name] = "Must have a name"
      end

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
      parent_id = params[:parent_id]
      if !parent_id.empty?
        parent = Activity.find(parent_id)
        parent.add_child(new_activity)
      end

      return errors

    end
  end
end
