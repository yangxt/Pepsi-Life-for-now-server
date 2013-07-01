class CreateFriendship < ActiveRecord::Migration
  def up
  	create_table :friendships do |t|
      t.references :user1
      t.references :user2
    end
  end

  def down
  	drop_table :friendships
  end
end
