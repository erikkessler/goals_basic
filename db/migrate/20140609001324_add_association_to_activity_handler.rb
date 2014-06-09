class AddAssociationToActivityHandler < ActiveRecord::Migration
  def change
    add_column :activity_handlers, :user_id, :integer
  end
end
