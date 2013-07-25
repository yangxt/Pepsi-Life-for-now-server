class CreateTag < ActiveRecord::Migration
  def self.up
  	create_table :tags do |t|
  		t.string :text
  		t.references :post
  	end
  end

  def self.down
  	drop_table :tags
  end
end
