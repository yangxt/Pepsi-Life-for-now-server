class Tag < ActiveRecord::Base
	validate :post, :presence => true
	validate :text, :length => {:maximum: 255}
	belongs_to :post, :inverse_of => :tags
end