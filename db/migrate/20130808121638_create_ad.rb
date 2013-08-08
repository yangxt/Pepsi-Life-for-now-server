class CreateAd < ActiveRecord::Migration
  def self.up
  	create_table :ads do |t|
  		t.text :image_url
  		t.float :duration
  	end
  end

  def self.down
  	drop_table :ads
  end
end
