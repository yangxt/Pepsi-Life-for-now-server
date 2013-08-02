require "./models/friendship"

class ApplicationUser < ActiveRecord::Base
	validates :name, :username, :password, :length => {:maximum => 255}
	has_many :posts, :inverse_of => :application_user
	has_one :coordinate, :inverse_of => :application_user
	has_many :likes, :inverse_of => :application_user
	has_many :seens, :inverse_of => :application_user
	has_many :comments, :inverse_of => :application_user

	def friends()
		friends_query_parameters = {
			:limit => Constants::USERS_MAX,
			:joins => "INNER JOIN friendships ON application_users.id = friendships.user1_id LEFT JOIN coordinates ON friendships.user1_id = coordinates.application_user_id",
			:select => "application_users.*, coordinates.latitude, coordinates.longitude",
			:group => "application_users.id, coordinates.id",
			:conditions => ["user2_id = :id", {:id => self.id}]
		}

		friends_query2_parameters = {
			:joins => "INNER JOIN friendships ON application_users.id = friendships.user2_id LEFT JOIN coordinates ON friendships.user2_id = coordinates.application_user_id",
			:select => "application_users.*, coordinates.latitude, coordinates.longitude",
			:group => "application_users.id, coordinates.id",
			:conditions => ["user1_id = :id", {:id => self.id}]
		}

		friends = ApplicationUser.find(:all, friends_query_parameters)
		friends_query2_parameters[:limit] = Constants::USERS_MAX - friends.count
		friends.concat(ApplicationUser.find(:all, friends_query2_parameters))
	end

	def friends_in_bounds(bounds)
		friends_query_parameters = {
			:limit => Constants::USERS_MAX,
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
		}

		friends_query2_parameters = {
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
		}

		friends = ApplicationUser.find(:all, friends_query_parameters)
		friends_query2_parameters[:limit] = Constants::USERS_MAX - friends.count
		friends.concat(ApplicationUser.find(:all, friends_query2_parameters))
	end

	def friend_by_id(id)
		friendship = Friendship.where(["(user1_id = #{self.id} and user2_id = :friend_id) or (user1_id = :friend_id and user2_id = #{self.id})", {:friend_id => id}])
		return nil if friendship.length == 0
		ApplicationUser.find(id)
	end

	def self.posts_counts_for_users(users)
		users_ids = users_ids_for_users(users)

		posts_query_parameters = {
			:joins => "LEFT JOIN application_users ON application_users.id = posts.application_user_id",
			:select => "count(posts.application_user_id) as count, posts.application_user_id",
			:group => "posts.application_user_id",
			:conditions => ["posts.application_user_id in (:users_ids)", {:users_ids => users_ids}]
		}

		posts_counts = Post.find(:all, posts_query_parameters)
	end

	def self.likes_counts_for_users(users)
		users_ids = users_ids_for_users(users)

		likes_query_parameters = {
			:joins => "LEFT JOIN application_users ON application_users.id = likes.application_user_id",
			:select => "count(likes.application_user_id) as count, likes.application_user_id",
			:group => "likes.application_user_id",
			:conditions => ["likes.application_user_id in (:users_ids)", {:users_ids => users_ids}]
		}

		likes_counts = Like.find(:all, likes_query_parameters)
	end

	def self.seens_counts_for_users(users)
		users_ids = users_ids_for_users(users)

		seens_query_parameters = {
			:joins => "LEFT JOIN application_users ON application_users.id = seens.application_user_id",
			:select => "count(seens.application_user_id) as count, seens.application_user_id",
			:group => "seens.application_user_id",
			:conditions => ["seens.application_user_id in (:users_ids)", {:users_ids => users_ids}]
		}

		seens_counts = Seen.find(:all, seens_query_parameters)
	end

	private
	def self.users_ids_for_users(users)
		users_ids = []
		users.each do |p|
			users_ids << p.id
		end
		users_ids
	end
end