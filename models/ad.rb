class Ad < ActiveRecord::Base
	validates :image_url, :duration, :presence => true
end