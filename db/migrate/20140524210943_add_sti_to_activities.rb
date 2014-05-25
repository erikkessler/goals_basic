class AddStiToActivities < ActiveRecord::Migration
  def change
    remove_column :activities, :title
    add_column :activities, :name, :string
    add_column :activities, :description, :text
    add_column :activities, :complete, :boolean
    add_column :activities, :completed_date, :datetime
    add_column :activities, :user_id, :integer
    add_column :activities, :integration_info, :string
    add_column :activities, :type, :string
    add_column :activities, :priority, :integer
    add_column :activities, :role_id, :integer
    add_column :activities, :value, :decimal, :precision => 8, :scale => 2
    add_column :activities, :weight, :decimal, :precision => 8, :scale => 2
    add_column :activities, :goal, :boolean

  end
end
