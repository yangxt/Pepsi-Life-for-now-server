class CreatePost < ActiveRecord::Migration
  def up
  	create_table :posts do |t|
  		t.string :title
  		t.text :text
  		t.text :image_url
  		t.datetime :creation_date
  		t.references :application_user
  	end
  end

  def down
  	drop_table :posts
  end
end
