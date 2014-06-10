class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.integer :user_id
      t.integer :activity_id
      t.integer :level

      t.timestamps
    end
  end
end
