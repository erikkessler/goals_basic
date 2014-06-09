class Friendship < ActiveRecord::Base

  belongs_to :user
  belongs_to :friend, :class_name => "User"

  MENTOR = 0
  STUDENT = 1
  FOLLOWER = 2
end
