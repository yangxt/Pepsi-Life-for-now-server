class CreateSeen < ActiveRecord::Migration
  def up
  	create_table :seens do |t|
  		t.references :application_user
  		t.references :post
  	end
  end

  def down
  	drop_table :seens
  end
end
