class CreateApplicationUser < ActiveRecord::Migration
  def up
  	create_table :application_users do |t|
  		t.string :username
  		t.string :password
  		t.string :name
  		t.text :image_url
  		t.references :coordinate
  	end
  end

  def down
  	drop_table :application_users
  end
end
