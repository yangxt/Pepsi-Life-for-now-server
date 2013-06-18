class CreateComment < ActiveRecord::Migration
  def up
  	create_table :comments do |t|
  		t.text :text
  		t.datetime :creation_date
  		t.references :post
  		t.references :application_user
  	end
  end

  def down
  	drop_table :comments
  end
end
