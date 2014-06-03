class Type < ActiveRecord::Base
  belongs_to :type_group

  # constants

  FULL_TASK = 0
  PARTIAL_TASK = 1
  HABIT = 2
  HABIT_NUMBER = 3
  HABIT_WEEK = 4
  GOAL = 5
  PROGRESS_SUM = 6
  PROGRESS_AVG = 7
  PROGRESS_MAX = 8

end
