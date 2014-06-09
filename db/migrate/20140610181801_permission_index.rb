class PermissionIndex < ActiveRecord::Migration
  def change
    add_column :users, :set_rewards, :boolean, :default => true, :null => false
    add_index :permissions, :user_id
    add_index :permissions, :activity_id
  end
end