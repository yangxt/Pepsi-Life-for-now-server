class CreateLike < ActiveRecord::Migration
  def up
  	create_table :likes do |t|
  		t.references :application_user
  		t.references :post
  	end
  end

  def down
  	drop_table :likes
  end
end
