class ActivityHandlerController < ApplicationController

  def new
    handler = ActivityHandler.find(1)
    @activities = handler.get_parentable
    @errors = { }
    @values = { :show_date => Date.current}
  end
  
  def create
    @values = params
    handler = ActivityHandler.find(1)
    @activities = handler.get_parentable
    @errors = handler.create_activity(params)
    if !@errors[:new_act].nil?
      redirect_to :action => "today"
    else
      render 'new'
    end
  end

  def show
    @activity = Activity.find(params[:id])
  end

  def today
    handler = ActivityHandler.find(1)
    today = handler.get_today
    @complete = today[:complete]
    @incomplete = today[:incomplete]
    @overdue = today[:overdue]

  end

  def index
    redirect_to :action => "today"
  end

  def toggle
    handler = ActivityHandler.find(1)
    flash[:notice] = handler.toggle(params[:id])
    redirect_to :action => "today"
  end

  def destroy
    handler = ActivityHandler.find(1)
    flash[:notice] = handler.remove_act(params[:id])
    redirect_to :action => "today"
  end
end
