class CreateActivityHandlers < ActiveRecord::Migration
  def change
    create_table :activity_handlers do |t|

      t.timestamps
    end
  end
end
