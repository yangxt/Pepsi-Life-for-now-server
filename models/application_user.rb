class ApplicationUser < ActiveRecord::Base
	validates :name, :username, :password, :length => {:maximum => 255}
	has_many :posts, :inverse_of => :application_user
	has_one :coordinate, :inverse_of => :application_user
	has_many :likes, :inverse_of => :application_user
	has_many :seens, :inverse_of => :application_user
	has_many :comments, :inverse_of => :application_user
end