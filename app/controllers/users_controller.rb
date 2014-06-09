class UsersController < ApplicationController

  include SessionsHelper, UsersHelper

  before_action :signed_in_user, only: [:edit,:update, :index]
  before_action :correct_user, only: [:edit, :update, :destroy, :show]
  before_action :admin_user, only: [:index]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      sign_in @user
      add_ah @user
      Rails.logger.debug "#{DateTime.current} - #{@user.email} created an account"
      redirect_to root_url, :notice => "Signed Up!"
    else
      render "new"
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def show
    @user = User.find(params[:id])
  end

  def index
    @users = User.all
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      redirect_to @user, :notice => "Profile Updated..."
    else
      render 'edit'
    end
  end

  def destroy
    user = User.find(params[:id])
    user.activity_handler.destroy
    user.permissions.where("level is ?", Permission::PRIVATE).each {|p| p.activity.destroy }
    user.permissions.destroy_all
    user.destroy
    Rails.logger.debug "#{DateTime.current} - #{user.email}'s account removed"
    redirect_to users_path, :notice => "User deleted."
  end

  private
    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end

    # Before filters
    def signed_in_user
      store_location
      redirect_to log_in_path, :notice => "Sign in required." unless signed_in?
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to root_path unless current_user?(@user) || current_user.admin?
    end

    def admin_user
      if !current_user.admin?
        redirect_to root_path, :flash => { :notice => "You must be admin to do that" }
      end
    end

  
end
