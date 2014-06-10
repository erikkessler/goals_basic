class CreateFeedItems < ActiveRecord::Migration
  def change
    create_table :feed_items do |t|
      t.integer :user_id
      t.string :message

      t.timestamps
    end
  end
end
