class ActivityHandlerController < ApplicationController

  def new
    @activities = Activity.where("state is ? AND rep_parent_id is ?",
                                 Activity::INCOMPLETE, nil)
    @errors = { }
    @values = { :show_date => Date.current}
  end
  
  def create
    @activities = Activity.where("state is ? AND rep_parent_id is ?",
                                 Activity::INCOMPLETE, nil)
    @values = params
    handler = ActivityHandler.find(1)
    @errors = handler.create_activity(params)
    if !@errors[:new_act].nil?
      redirect_to :action => "show", :id => @errors[:new_act].id
    else
      render 'new'
    end
  end

  def show
    @activity = Activity.find(params[:id])
  end
end
