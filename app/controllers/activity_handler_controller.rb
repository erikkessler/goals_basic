# Each user has an ActivityHandler and it is through the handler that all CRUD operations are
# preformed. This allows us to take the logic out of both the User class and Activity class 
# and keep it as its own seperate entity. 

class ActivityHandlerController < ApplicationController
  include SessionsHelper

  # Creating a new activity
  def new
    # make sure there is a user
    if current_user
      handler = current_user.activity_handler
      @activities = handler.get_parentable(current_user)
      @errors = { }
      @values = { :show_date => Date.current, :habit_type => 'none', :period => 2,
        :type_group => 1} # set some defaults
      @method = :post
      @path = '/activity_handler'
    else
      # if not make them sign it
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
    
  end
  
  def create
    if current_user
      handler = current_user.activity_handler

      # create the activity, if there is a new_act there were no errors
      @errors = handler.create_activity(params, current_user)
      if !@errors[:new_act].nil?
        redirect_to :action => "today"
      else
        # there were errors, prep to render the form again
        @values = params
        if @values[:habit_type].nil?
          @values[:habit_type] = 'none'
        end
        @activities = handler.get_parentable(current_user)
        @method = :post
        @path = '/activity_handler'
        render 'new'
      end
    else
      redirect_to log_in_path, :notice => "Sign in required."
    end
    
  end

  # Shows the details of an activity
  def show
    if current_user
      handler = current_user.activity_handler
      @activity = handler.find_act(params[:id], current_user)
    else
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end

  # Shows the activities for the day
  def today
    if signed_in?
      handler = current_user.activity_handler
      today = handler.get_today(current_user)
      @complete = today[:complete]
      @incomplete = today[:incomplete]
      @overdue = today[:overdue]
      # get the weekly payout
      @week_payout = 0
      handler.roots(true).each {|act| @week_payout += handler.get_week_reward(act, Date.current, current_user) }
    else
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
    

  end

  # Redirect to today
  def index
    redirect_to :action => "today"
  end

  # For changing the state of an activity
  def toggle
    if current_user
      handler = current_user.activity_handler
      flash[:notice] = handler.toggle(params[:id], current_user)
      redirect_to :action => "today"
    else
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end

  # For removing activities
  def destroy
    if current_user
      handler = current_user.activity_handler
      flash[:notice] = handler.remove_act(params[:id], current_user)
      redirect_to :action => "today"
    else
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end

  # For editing activities
  def edit
    if current_user
      handler = current_user.activity_handler
      @activities = handler.get_parentable(current_user)
        .where.not(:id => handler.it_and_children(params[:id]))
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
        @activities = handler.get_parentable(current_user)
          .where.not(:id => handler.it_and_children(params[:id]))
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

  # Displays activities of the week
  def week
    if current_user
      handler = current_user.activity_handler
      if params[:date].nil?
        redirect_to :action => "week", :date => 'this_week'
      else
        handler = current_user.activity_handler
        @days = handler.week(params[:date], :monday, current_user)
      end
    else
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end

  # Structure of the chld/parent relationships
  def overview
    if current_user
      handler = current_user.activity_handler
      @roots = handler.roots(true, current_user)
    else
      store_location
      redirect_to log_in_path, :notice => "Sign in required."
    end
  end
end
