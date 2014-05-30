class Repeatable < Activity

  # used to calculate repeated days
  DAY_VALUES = {0 => 2, 1 => 3, 2 => 5, 3 => 7, 4 => 11, 5 => 13, 6 => 17}

  # inheritance
  self.inheritance_column = :type
  scope :habits, -> { where(type:'Habit') }

  # allow to track its repititions
  has_many :repititions, class_name: "Repeatable",
    foreign_key: "rep_parent_id"
  belongs_to :rep_parent, class_name: "Repeatable", foreign_key: "rep_parent_id"


  # generates reps for the given range
  def gen_reps(start_date = Date.current,
               end_date = Date.current.advance(:weeks => 1))

    # must be the rep_parent
    if !self.rep_parent.nil?
      self.rep_parent.gen_reps
      return
    end

    # check dates are dates
    if !start_date.is_a?(Date) or !end_date.is_a?(Date)
      puts "start_date and end_date must be dates"
      return
    end

    # make sure
    if start_date > end_date
      puts "start_date after end_date"
      return
    end

    date_range = start_date..end_date
    date_range.each do |date|
      if is_repeated_day(date)
        new_act = self.dup
        new_act.show_date = date
        new_act.parent_id = nil
        new_act.save!
        self.repititions << new_act
      end
    end
  end
  
  # returns true if repeated act should show on that day
  def is_repeated_day(day_int)
    if day_int.is_a?(Date)
      day_int = day_int.wday
    end

    day_int = DAY_VALUES[day_int]
    act_int = repeated

    if act_int.nil? or day_int.nil?
      return false
    end

    return (act_int % day_int) == 0
    
  end

  # takes an array of wdays and sets repeated
  def set_repeated(days)
    if days.class != Array
      puts "days must be an array"
      return nil
    end

    count = 1
    days.each do |day|
      result = DAY_VALUES[day]
      if !result.nil?
        count = count * result
      end
    end

    if count != 1
      self.repeated = count
      self.save!
      return count
    else
      return nil
    end
  end
  
  # returns array corresponding to wdays
  def get_repeated
    if self.repeated.nil?
      return nil
    end

    days = Array.new
    DAY_VALUES.each do |k,v|
      if (self.repeated % v) == 0
        days << k
      end
    end

    return days
  end

  # override parent method to always return parent of rep_parent
  def parent
    if self.rep_parent.nil?
      if self.parent_id.nil?
        return nil
      else
        return Activity.find(self.parent_id)
      end

    else
      return self.rep_parent.parent
    end
  end
  
  # deletes reps past date
  def del_reps(start_date = Date.tomorrow)
    if start_date.is_a?(Date)
      if !self.rep_parent.nil?
        return self.rep_parent.del_reps(start_date)
      else
        self.repititions.where("show_date >= :date", date: start_date).destroy_all
      end
    end
  end

  # sets parent
  def set_parent(new_parent)
    if new_parent.is_a? Activity
      old_parent = self.parent
      if !self.rep_parent.nil?
        return self.rep_parent.set_parent(new_parent)
      end
      new_parent.children << self
      self.parent_id = new_parent.id
      self.is_root = false
      self.save!
      new_parent.is_complete?
      
      if old_parent != nil
        old_parent.children.delete(self)
        old_parent.is_complete? # in case depends on 
      end
      return true
    else
      return false
    end
  end
  
end
