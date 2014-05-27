class AddRepParentToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :rep_parent_id, :integer
  end
end
