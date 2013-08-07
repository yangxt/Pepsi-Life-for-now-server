class CreateApplicationUser < ActiveRecord::Migration
  def self.up
  	create_table :application_users do |t|
  		t.string :username
  		t.string :password
  		t.string :name, :default => "Unkown"
  		t.text :image_url
      t.text :description
  	end
  end

  def self.down
  	drop_table :application_users
  end
end
