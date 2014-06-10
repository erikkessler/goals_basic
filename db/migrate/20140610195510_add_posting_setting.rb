class AddPostingSetting < ActiveRecord::Migration
  def change
    add_column :activities, :report_to, :integer, :default => 0, :null => false
  end
end
