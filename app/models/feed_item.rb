class FeedItem < ActiveRecord::Base

  belongs_to :user

  def self.from_users_followed_by(user)
    followed_user_ids = "SELECT friend_id FROM friendships
                         WHERE user_id = :user_id"
    order("created_at desc").where("user_id IN (#{followed_user_ids}) OR user_id = :user_id",
          user_id: user.id)
  end
end
