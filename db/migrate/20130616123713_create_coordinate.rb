class CreateCoordinate < ActiveRecord::Migration
  def self.up
  	create_table :coordinates do |t|
  		t.float :latitude
  		t.float :longitude
  		t.references :application_user
  	end
  end

  def self.down
  	drop_table :coordinates
  end
end
