class Friendship < ActiveRecord::Base
	validates :user1, :user2, :presence => true
	belongs_to :user1, :class_name => "ApplicationUser"
	belongs_to :user2, :class_name => "ApplicationUser"
end