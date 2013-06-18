class Coordinate < ActiveRecord::Base
	validates :latitude, :longitude, :numericality => true
	validates :application_user, :latitude, :longitude, :presence => true
	belongs_to :application_user, :inverse_of => :coordinate
end