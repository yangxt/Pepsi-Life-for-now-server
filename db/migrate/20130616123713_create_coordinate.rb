class CreateCoordinate < ActiveRecord::Migration
  def up
  	create_table :coordinates do |t|
  		t.float :latitude
  		t.float :longitude
  		t.references :application_user
  	end
  end

  def down
  	drop_table :coordinates
  end
end
