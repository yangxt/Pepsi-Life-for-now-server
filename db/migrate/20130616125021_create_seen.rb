class CreateSeen < ActiveRecord::Migration
  def self.up
  	create_table :seens do |t|
  		t.references :application_user
  		t.references :post
  	end
  end

  def self.down
  	drop_table :seens
  end
end
