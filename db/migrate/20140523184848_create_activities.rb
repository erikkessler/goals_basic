class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.string :title
      t.integer :repeated
      t.date :due_date

      t.timestamps
    end
  end
end
