class AddDatesToHandler < ActiveRecord::Migration
  def change
    add_column :activity_handlers, :reset_date, :date
    add_column :activity_handlers, :upto_date, :date
  end
end
