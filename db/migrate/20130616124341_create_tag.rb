class CreateTag < ActiveRecord::Migration
  def up
  	create_table :tags do |t|
  		t.string :text
  		t.references :post
  	end
  end

  def down
  	drop_table :tags
  end
end
