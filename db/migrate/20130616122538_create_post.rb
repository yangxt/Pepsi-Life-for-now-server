class CreatePost < ActiveRecord::Migration
  def self.up
  	create_table :posts do |t|
  		t.text :text
  		t.text :image_url
  		t.datetime :creation_date
  		t.references :application_user
  	end
  end

  def self.down
  	drop_table :posts
  end
end
