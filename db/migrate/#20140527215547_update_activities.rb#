class UpdateActivities < ActiveRecord::Migration
  def change
    rename_column :activities, :due_date, :show_date
    add_column :activities, :expiration_date, :date
    remove_column :activities, :complete
    add_column :activities, :state, :integer, :default => 0, :null => false
    add_column :activities, :goal_type, :integer
    remove_column :activities, :value
    remove_column :activities, :weight
    add_column :activities, :reward, :integer, :default => 0, :null => false
    add_column :activities, :penalty, :intger, :default => 0, :null => false
    add_column :activities, :count, :integer, :default => 0, :null => false
    add_column :activities, :count_goal, :integer
    remove_column :activities, :goal
    add_column :activities, :is_root, :boolean, :default => true, :null => false
  end
end
