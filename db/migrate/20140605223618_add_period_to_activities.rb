class AddPeriodToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :period, :integer
  end
end
