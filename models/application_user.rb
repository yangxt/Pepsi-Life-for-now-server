require "./models/friendship"

class ApplicationUser < ActiveRecord::Base
	validates :name, :username, :password, :length => {:maximum => 255}
	has_many :posts, :inverse_of => :application_user
	has_one :coordinate, :inverse_of => :application_user
	has_many :likes, :inverse_of => :application_user
	has_many :seens, :inverse_of => :application_user
	has_many :comments, :inverse_of => :application_user

	def friends
		friends = ApplicationUser.find(
			:all,
			:joins => "INNER JOIN friendships ON application_users.id = friendships.user1_id LEFT JOIN coordinates ON friendships.user1_id = coordinates.application_user_id",
			:select => "application_users.*, coordinates.latitude, coordinates.longitude",
			:group => "application_users.id, coordinates.id",
			:conditions => ["user2_id = :id", {:id => self.id}]
		)

		friends.concat(ApplicationUser.find(
			:all,
			:joins => "INNER JOIN friendships ON application_users.id = friendships.user2_id LEFT JOIN coordinates ON friendships.user2_id = coordinates.application_user_id",
			:select => "application_users.*, coordinates.latitude, coordinates.longitude",
			:group => "application_users.id, coordinates.id",
			:conditions => ["user1_id = :id", {:id => self.id}]
		))
	end

	def friends_in_bounds(bounds)
		friends = ApplicationUser.find(
			:all,
			:joins => "INNER JOIN friendships ON application_users.id = friendships.user1_id LEFT JOIN coordinates ON friendships.user1_id = coordinates.application_user_id",
			:select => "application_users.*, coordinates.latitude, coordinates.longitude",
			:group => "application_users.id, coordinates.id",
			:conditions => ["user2_id = :id and \
				coordinates.latitude >= :from_lat and coordinates.latitude <= :to_lat and\
				coordinates.longitude >= :from_long and coordinates.longitude <= :to_long", 
				{:id => self.id,
				:from_lat => bounds[:from_lat],
				:to_lat => bounds[:to_lat],
				:from_long => bounds[:from_long],
				:to_long => bounds[:to_long]}]
		)

		friends.concat(ApplicationUser.find(
			:all,
			:joins => "INNER JOIN friendships ON application_users.id = friendships.user2_id LEFT JOIN coordinates ON friendships.user2_id = coordinates.application_user_id",
			:select => "application_users.*, coordinates.latitude, coordinates.longitude",
			:group => "application_users.id, coordinates.id",
			:conditions => ["user1_id = :id and \
				coordinates.latitude >= :from_lat and coordinates.latitude <= :to_lat and\
				coordinates.longitude >= :from_long and coordinates.longitude <= :to_long", 
				{:id => self.id,
				:from_lat => bounds[:from_lat],
				:to_lat => bounds[:to_lat],
				:from_long => bounds[:from_long],
				:to_long => bounds[:to_long]}]
		))
	end

	def friend_by_id(id)
		friendship = Friendship.where(["(user1_id = #{self.id} and user2_id = :friend_id) or (user1_id = :friend_id and user2_id = #{self.id})", {:friend_id => id}])
		return nil if friendship.length == 0
		ApplicationUser.find(id)
	end
end