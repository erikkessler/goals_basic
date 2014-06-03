class ActivityHandlerController < ApplicationController

  def new
    @activities = Activity.where("state is ? AND rep_parent_id is ?",
                                 Activity::INCOMPLETE, nil)
  end
  
  def create
    
    handler = ActivityHandler.find(1)
    if handler.create_activity(params)
      redirect_to 'http://google.com'
    else
      redirect_to '/activity_handler/new'
    end
  end
end
