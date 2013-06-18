class Comment < ActiveRecord::Base
	validates :text, :creation_date, :presence => true
	belongs_to :post, :inverse_of => :comments
	belongs_to :application_user, :inverse_of => :comments
end