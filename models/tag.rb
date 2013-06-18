class Tag < ActiveRecord::Base
	validates :post, :text, :presence => true
	validates :text, :length => {:maximum => 255}
	belongs_to :post, :inverse_of => :tags
end