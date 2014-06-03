class CreateTypes < ActiveRecord::Migration
  def change
    create_table :types do |t|
      t.string :name
      t.text :description
      t.references :type_group, index: true

      t.timestamps
    end
  end
end
