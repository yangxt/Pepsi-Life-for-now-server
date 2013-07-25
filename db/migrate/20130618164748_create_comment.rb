class CreateComment < ActiveRecord::Migration
  def self.up
  	create_table :comments do |t|
  		t.text :text
  		t.datetime :creation_date
  		t.references :post
  		t.references :application_user
  	end
  end

  def self.down
  	drop_table :comments
  end
end
