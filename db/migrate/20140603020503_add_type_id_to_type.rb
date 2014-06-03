class AddTypeIdToType < ActiveRecord::Migration
  def change
    add_column :types, :type_id, :integer
  end
end