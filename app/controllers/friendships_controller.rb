class FriendshipsController < ApplicationController
  include SessionsHelper

  before_action :signed_in_user

  def create
    friend = User.find_by_email(params[:email])
    if friend.nil?
      @errors = "No user found with that email"
      render 'new'
    elsif current_user.id == friend.id
      @errors = "You can't friend yourself"
      render 'new'
    elsif !current_user.friendships.find_by_friend_id(friend.id).nil?
      @errors = "Friendship already exists"
      render 'new'
    else
      rel_type = nil
      params[:mentor] == 'yes' ? rel_type = Friendship::MENTOR : rel_type = Friendship::FOLLOWER
      @friendship = current_user.friendships.build(:friend_id => friend.id,
                                                   :kind => rel_type)
      if @friendship.save
        flash[:notice] = "Added friend."
        redirect_to root_url
      else
        flash[:error] = "Unable to add friend."
        redirect_to root_url
      end
    end
  end

  def destroy
    @friendship = current_user.friendships.find(params[:id])
    @friendship.destroy
    flash[:notice] = "Removed friendship."
    redirect_to current_user
  end

  private
    # Before filters
    def signed_in_user
      store_location
      redirect_to log_in_path, :notice => "Sign in required." unless signed_in?
    end
end
