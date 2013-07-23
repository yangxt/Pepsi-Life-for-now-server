require "./models/tag"
require "./models/like"
require "./models/seen"

class Post < ActiveRecord::Base
	validates :application_user, :image_url, :text, :creation_date, :presence => true
	belongs_to :application_user, :inverse_of => :posts
	has_many :tags, :inverse_of => :post
	has_many :likes, :inverse_of => :post
	has_many :seens, :inverse_of => :post
	has_many :comments, :inverse_of => :post

	def self.tags_for_posts(posts)
		posts_ids = posts_ids_for_posts(posts)
		tags_query_parameters = {
			:joins => "LEFT JOIN posts ON posts.id = tags.post_id",
			:select => "tags.text, tags.post_id",
			:conditions => ["tags.post_id in (:posts_ids)", {:posts_ids => posts_ids}]
		}

		Tag.find(:all, tags_query_parameters)
	end

	def self.likes_counts_for_posts(posts)
		posts_ids = posts_ids_for_posts(posts)

		likes_query_parameters = {
			:joins => "LEFT JOIN posts ON posts.id = likes.post_id",
			:select => "count(likes.application_user_id) as count, likes.post_id",
			:group => "likes.post_id",
			:conditions => ["likes.post_id in (:posts_ids)", {:posts_ids => posts_ids}]
		}

		likes_counts = Like.find(:all, likes_query_parameters)
	end

	def self.seens_counts_for_posts(posts)
		posts_ids = posts_ids_for_posts(posts)

		seens_query_parameters = {
			:joins => "LEFT JOIN posts ON posts.id = seens.post_id",
			:select => "count(seens.application_user_id) as count, seens.post_id",
			:group => "seens.post_id",
			:conditions => ["seens.post_id in (:posts_ids)", {:posts_ids => posts_ids}]
		}

		seens_counts = Seen.find(:all, seens_query_parameters)
	end

	def self.comments_counts_for_posts(posts)
		posts_ids = posts_ids_for_posts(posts)

		comments_query_parameters = {
			:joins => "LEFT JOIN posts ON posts.id = comments.post_id",
			:select => "count(comments.application_user_id) as count, comments.post_id",
			:group => "comments.post_id",
			:conditions => ["comments.post_id in (:posts_ids)", {:posts_ids => posts_ids}]
		}

		comments_counts = Comment.find(:all, comments_query_parameters)
	end

	def self.users_for_posts(posts)
		posts_ids = posts_ids_for_posts(posts)

		users_query_parameters = {
	       	:joins => "LEFT JOIN posts ON posts.application_user_id = application_users.id",
	       	:select => "application_users.id, posts.id as post_id",
	        :order => "posts.id DESC",
	        :conditions => ["posts.id in (:posts_ids)", {:posts_ids => posts_ids}]
		}

		users = ApplicationUser.find(:all, users_query_parameters);
	end

	def self.seen_posts_for_user(user)
		posts_query_parameters = {
	       	:joins => "INNER JOIN seens ON posts.id = seens.post_id",
	       	:select => "posts.id",
	        :order => "posts.id DESC",
	        :group => "posts.id",
	        :conditions => ["seens.application_user_id = :user_id", {:user_id => user.id}]
		}

		posts = Post.find(:all, posts_query_parameters);
	end

	def self.liked_posts_for_user(user)
		posts_query_parameters = {
	       	:joins => "INNER JOIN likes ON posts.id = likes.post_id",
	       	:select => "posts.id",
	        :order => "posts.id DESC",
	        :group => "posts.id",
	        :conditions => ["likes.application_user_id = :user_id", {:user_id => user.id}]
		}

		posts = Post.find(:all, posts_query_parameters);
	end

	private
	def self.posts_ids_for_posts(posts)
		posts_ids = []
		posts.each do |p|
			posts_ids << p.id
		end
		posts_ids
	end

end