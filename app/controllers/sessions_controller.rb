class SessionsController < ApplicationController

  include SessionsHelper

  def new
  end

  def create
    user = User.authenticate(params[:email], params[:password])
    if !user.nil?
      sign_in user
      redirect_back_or root_url, "Logged in!"
    else
      flash.now.alert = "Invalid email or password"
      render "new"
    end
  end

  def destroy
    sign_out
    redirect_to root_url, :notice => "Logged out!"
  end

end
