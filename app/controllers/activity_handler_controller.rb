class ActivityHandlerController < ApplicationController

  def new
    @activities = Activity.where("state is ? AND rep_parent_id is ?",
                                 Activity::INCOMPLETE, nil)
    @errors = { }
    @values = { }
  end
  
  def create
    @activities = Activity.where("state is ? AND rep_parent_id is ?",
                                 Activity::INCOMPLETE, nil)
    @values = params
    handler = ActivityHandler.find(1)
    @errors = handler.create_activity(params)
    if @errors.empty?
      redirect_to 'http://google.com'
    else
      render 'new'
    end
  end
end
