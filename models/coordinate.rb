class Coordinate < ActiveRecord::Base
	validate :latitude, :longitude, :numericality => true
	validate :application_user, :presence => true
	belongs_to :application_user, :inverse_of => :coordinate
end