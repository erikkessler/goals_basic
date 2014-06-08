class ActivityHandlerController < ApplicationController

  def new
    handler = ActivityHandler.find(1)
    @activities = handler.get_parentable
    @errors = { }
    @values = { :show_date => Date.current, :habit_type => 'none', :period => 2,
    :type_group => 1}
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
      if @values[:habit_type].nil?
        @values[:habit_type] = 'none'
      end
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
    @week_payout = 0
    handler.roots(true).each {|act| @week_payout += handler.get_week_reward(act, Date.current) }

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
    @activities = handler.get_parentable.where.not(:id => handler.it_and_children(params[:id]))
    @errors = { }
    @values = handler.get_attributes(params)
    @method = :patch
    @path = "/activity_handler/#{params[:id]}"
  end

  def update
    handler = ActivityHandler.find(1)
    @errors = handler.check_form_errors(params, true)
    if !@errors.empty?
      @values = params
      @activities = handler.get_parentable.where.not(:id => handler.it_and_children(params[:id]))
      @method = :patch
      @path = "/activity_handler/#{params[:id]}"
      render 'edit'
    else
      handler.update_act(params)
      redirect_to :action => "today"
    end
  end

  def week
    if params[:date].nil?
      redirect_to :action => "week", :date => 'this_week'
    else
      handler = ActivityHandler.find(1)
      @days = handler.week(params[:date], :monday)
    end
  end

  def overview
    handler = ActivityHandler.find(1)
    @roots = handler.roots
  end
end
