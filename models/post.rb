class Post < ActiveRecord::Base
	validates :application_user, :image_url, :text, :creation_date, :presence => true
	belongs_to :application_user, :inverse_of => :posts
	has_many :tags, :inverse_of => :post
	has_many :likes, :inverse_of => :post
	has_many :seens, :inverse_of => :post
	has_many :comments, :inverse_of => :post
end