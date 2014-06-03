class CreateTypeGroups < ActiveRecord::Migration
  def change
    create_table :type_groups do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
