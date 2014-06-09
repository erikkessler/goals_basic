module UsersHelper

  def add_ah(user)
    date = Date.current
    sunday = date.end_of_week
    reset = sunday.advance(:weeks => 2)
    upto = sunday.advance(:weeks => 2)
    user.create_activity_handler :reset_date => reset, :upto_date => upto
  end
end
