class Like < ActiveRecord::Base
	validate :post, :application_user, :presence => true
	belongs_to :post, :inverse_of => :likes
	belongs_to :application_user, :inverse_of => :likes
end