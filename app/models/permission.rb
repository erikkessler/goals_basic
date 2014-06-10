class Permission < ActiveRecord::Base

  belongs_to :user
  belongs_to :activity
  
  PRIVATE = 0
  SHARED_OWNER = 1
  SHARED_RECIPIENT = 2
  SHARED_RECIPIENT_VIEW_ONLY = 3
  FOR_USER = 4
  FOR_USER_VIEW_ONLY = 5
  FROM_USER = 6
  

  def is_owner?
    return self.level <= 1
  end

  def can_edit?
    return [0,1,2,4,6].include? (self.level)
  end

end
