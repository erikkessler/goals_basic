# Each user has an ActivityHandler and it is through the handler that all CRUD operations are
# preformed. This allows us to take the logic out of both the User class and Activity class 
# and keep it as its own seperate entity. 

class ActivityHandlerController < ApplicationController
  include SessionsHelper

  before_action :signed_in_user
  before_action :activity_not_in_past, only: [:edit, :update, :toggle]
  before_action :can_edit, only: [:edit, :update, :destroy]

  # Creating a new activity
  def new
    handler = current_user.activity_handler
    @activities = handler.get_parentable(current_user)
    @errors = { }
    @values = { :show_date => Date.current, :habit_type => 'none', :period => 2,
      :type_group => 1, :report_to => 0} # set some defaults
    @method = :post
    @path = '/activity_handler'   
  end
  
  def create
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
  end

  # Shows the details of an activity
  def show
    handler = current_user.activity_handler
    @activity = handler.find_act(params[:id], current_user)
  end

  # Shows the activities for the day
  def today
      handler = current_user.activity_handler
      today = handler.get_today(current_user)
      @complete = today[:complete]
      @incomplete = today[:incomplete]
      @overdue = today[:overdue]
      # get the weekly payout
      @week_payout = 0
      handler.roots(true, current_user).each {|act| @week_payout += handler.get_week_reward(act, Date.current) }
  end

  # Redirect to today
  def index
    redirect_to :action => "today"
  end

  # For changing the state of an activity
  def toggle
    handler = current_user.activity_handler
    flash[:notice] = handler.toggle(params[:id], current_user)
    redirect_to :action => "today"
  end

  # For removing activities
  def destroy
    handler = current_user.activity_handler
    flash[:notice] = handler.remove_act(params[:id], current_user)
    redirect_to :action => "today"
  end

  # For editing activities
  def edit
    handler = current_user.activity_handler
    @activities = handler.get_parentable(current_user)
      .where.not(:id => handler.it_and_children(params[:id], current_user))
    @errors = { }
    @values = handler.get_attributes(params, current_user)
    @method = :patch
    @path = "/activity_handler/#{params[:id]}"
  end

  def update
    handler = current_user.activity_handler
    @errors = handler.check_form_errors(params, true)
    if !@errors.empty?
      @values = params
      @activities = handler.get_parentable(current_user)
        .where.not(:id => handler.it_and_children(params[:id], current_user))
      @method = :patch
      @path = "/activity_handler/#{params[:id]}"
      render 'edit'
    else
      handler.update_act(params, current_user)
      redirect_to :action => "today"
    end
  end

  # Displays activities of the week
  def week
    handler = current_user.activity_handler
    if params[:date].nil?
      redirect_to :action => "week", :date => 'this_week'
    else
      handler = current_user.activity_handler
      @days = handler.week(params[:date], :monday, current_user)
    end
  end

  # Structure of the chld/parent relationships
  def overview
      handler = current_user.activity_handler
      @roots = handler.roots(true, current_user)
  end

  private
    # before filters
    def signed_in_user
      store_location
      redirect_to log_in_path, :notice => "Sign in required." unless signed_in?
    end

    def activity_not_in_past
      act = current_user.activity_handler.find_act(params[:id], current_user)
      return redirect_to activity_handler_path, :notice => "Can't edit a past task" unless act.show_date >= Date.current
    end

    def can_edit
      redirect_to activity_handler_path, :notice => "You don't have permission to edit" unless current_user.permissions.where("activity_id is ?", params[:id])[0].can_edit?
    end
end
