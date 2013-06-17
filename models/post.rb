class Post < ActiveRecord::Base
	validate :title, :length => {:maximum => 255}
	validate :application_user, :presence => true
	belongs_to :application_user, :inverse_of => :posts
	has_many :tags, :inverse_of => :post
	has_many :likes, :inverse_of => :post
	has_many :seens, :inverse_of => :post
end