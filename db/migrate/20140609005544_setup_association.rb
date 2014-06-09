class SetupAssociation < ActiveRecord::Migration
  def change
    remove_column :users, :activity_handler_id
  end
end
