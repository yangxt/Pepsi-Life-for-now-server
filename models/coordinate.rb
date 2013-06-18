class Coordinate < ActiveRecord::Base
	validates :latitude, :longitude, :numericality => true
	validates :application_user, :presence => true
	belongs_to :application_user, :inverse_of => :coordinate
end