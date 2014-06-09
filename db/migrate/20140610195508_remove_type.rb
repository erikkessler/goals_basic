class RemoveType < ActiveRecord::Migration
  def change
    remove_column :friendships, :type
    add_column :friendships, :kind, :integer
  end
end