class ActivityHandlerController < ApplicationController

  def new
    handler = ActivityHandler.find(1)
    @activities = handler.get_parentable
    @errors = { }
    @values = { :show_date => Date.current}
    @method = :post
    @path = '/activity_handler'
  end
  
  def create
    handler = ActivityHandler.find(1)
    @errors = handler.create_activity(params)
    if !@errors[:new_act].nil?
      redirect_to :action => "today"
    else
      @values = params
      @activities = handler.get_parentable
      @method = :post
      @path = '/activity_handler'
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

  def edit
    handler = ActivityHandler.find(1)
    @activities = handler.get_parentable.where.not(:id => params[:id])
    @errors = { }
    @values = Activity.find(params[:id]).attributes.symbolize_keys 
    @method = :patch
    @path = "/activity_handler/#{params[:id]}"
  end

  def update
    handler = ActivityHandler.find(1)
    @errors = handler.check_form_errors(params)
    if !@errors.empty?
      @values = params
      @activities = handler.get_parentable.where.not(:id => params[:id])
      @method = :patch
      @path = "/activity_handler/#{params[:id]}"
      render 'edit'
    else
      Activity.find(params[:id]).destroy
      handler.create_activity(params)
      redirect_to :action => "today"
    end
  end
end
