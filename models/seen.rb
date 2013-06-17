class Seen < ActiveRecord::Base
	validate :application_user, :post, :presence => true
	belongs_to :application_user, :inverse_of => :seens
	belongs_to :post, :inverse_of => :seens
end