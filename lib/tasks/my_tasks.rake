namespace :advance do
  desc "Move incomplete from yesterday unless they expired"
  task :activities => :environment do
    yesterday = Activity.where("show_date is ? AND (state is ? OR state is ?)", 
                               Date.yesterday,
                               Activity::INCOMPLETE,
                               Activity::OVERDUE)
    yesterday.each do |act|
      if act.expiration_date.nil?
        act.show_date = Date.current
        act.state = Activity::OVERDUE
        
      elsif act.expiration_date >= Date.current
        act.show_date = Date.today
        act.state = Activity::OVERDUE
      else
        act.state = Activity::EXPIRED
      end

      act.save!
    end
    Rails.logger.debug "#{DateTime.current} - advanced activities"
  end

  desc "Every Sunday move up any ActivityHandler dates if it time to reset"
  task :handler => :environment do
    handlers = ActivityHandler.all
    handlers.each do |h|
      if h.reset_date == Date.current
        h.reset_date = h.upto_date
        h.upto_date = h.upto_date.advance(:weeks => 2)
        h.save!
      end
    end
    Rails.logger.debug "#{DateTime.current} - advanced handlers"
  end

end
