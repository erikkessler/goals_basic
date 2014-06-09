class ActivityHandlerController < ApplicationController
  include SessionsHelper

  def new
    if current_user
      handler = current_user.activity_handler
      @activities = handler.get_parentable
      @errors = { }
      @values = { :show_date => Date.current, :habit_type => 'none', :period => 2,
        :type_group => 1}
      @method = :post
      @path = '/activity_handler'
    else
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
    
  end
  
  def create
    if current_user
      handler = current_user.activity_handler
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
    else
      redirect_to log_in_path, :notice => "Sign in required."
    end
    
  end


  def show
    if current_user
      handler = current_user.activity_handler
      @activity = handler.find_act(params[:id])
    else
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end

  def today
    if signed_in?
      handler = current_user.activity_handler
      today = handler.get_today
      @complete = today[:complete]
      @incomplete = today[:incomplete]
      @overdue = today[:overdue]
      @week_payout = 0
      handler.roots(true).each {|act| @week_payout += handler.get_week_reward(act, Date.current) }
    else
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
    

  end

  def index
    redirect_to :action => "today"
  end

  def toggle
    if current_user
      handler = current_user.activity_handler
      flash[:notice] = handler.toggle(params[:id])
      redirect_to :action => "today"
    else
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end

  def destroy
    if current_user
      handler = current_user.activity_handler
      flash[:notice] = handler.remove_act(params[:id])
      redirect_to :action => "today"
    else
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end

  def edit
    if current_user
      handler = current_user.activity_handler
      @activities = handler.get_parentable.where.not(:id => handler.it_and_children(params[:id]))
      @errors = { }
      @values = handler.get_attributes(params)
      @method = :patch
      @path = "/activity_handler/#{params[:id]}"
    else
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end

  def update
    if current_user
      handler = current_user.activity_handler
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
    else
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end

  def week
    if current_user
      handler = current_user.activity_handler
      if params[:date].nil?
        redirect_to :action => "week", :date => 'this_week'
      else
        handler = ActivityHandler.find(1)
        @days = handler.week(params[:date], :monday)
      end
    else
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end

  def overview
    if current_user
      handler = current_user.activity_handler
      @roots = handler.roots
    else
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end
end
