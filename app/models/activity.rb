class Activity < ActiveRecord::Base

  validates :title, presence: true
  has_many :children, class_name: "Activity", foreign_key: "parent_id"
  belongs_to :parent, class_name: "Activity", foreign_key: "parent_id"

  @@day_converter = {0 => 2, 1 => 3, 2 => 5, 3 => 7, 4 => 9, 5 => 11, 6 => 13}

  
  def today
    todayInt = @@day_converter[Date.today.wday]
    activityInt = self.repeated
    if activityInt.nil?
      activityInt = 0
    end
    return (activityInt % todayInt) == 0
  end


end
