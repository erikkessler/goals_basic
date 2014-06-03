module MyModules
  
  # This module hold methods for the ActivityHelper to use
  module ActivityHelper
    
    # Creates an acitvity of the correct type
    def self.create_activity(type_id, params)
      # switch on type_id
      case type_id

      when ActivityHandler::FULL_TASK
        # ensure it has a show_date
        show_date = params[:show_date]
        if show_date.nil?
          Rails.logger.debug "No show date for full task"
          return false
        end

        # ensure it has a name
        name = params[:name]
        if name.nil?
          Rails.logger.debug "No name for full task"
          return false
        end
        
        # create the new task
        new_activity = FullTask.create(name: name, show_date: show_date, 
                                       description: params[:description],
                                       expiration_date: params[:expiration_date],
                                       reward: params[:reward],
                                       penalty: params[:penalty])

        # if it has a parent, add activity to it
        parent_id = params[:parent_id]
        if parent_id.empty?
          return true
        else
          parent = Activity.find(parent_id)
          parent.add_child(new_activity)
          return true
        end

      when ActivityHandler::PARTIAL_TASK
        Rails.logger.debug "Partial task not complete"
        return false
      else
        Rails.logger.debug "Invalid type_id"
      end
    end
  end
end
