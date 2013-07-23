class Comment < ActiveRecord::Base
	validates :text, :creation_date, :presence => true
	belongs_to :post, :inverse_of => :comments
	belongs_to :application_user, :inverse_of => :comments

	def self.users_for_comments(comments)
		comments_ids = comments_ids_for_comments(comments)

		users_query_parameters = {
	       	:joins => "LEFT JOIN comments ON comments.application_user_id = application_users.id",
	       	:select => "application_users.id, comments.id as comment_id",
	        :order => "comments.id DESC",
	        :conditions => ["comments.id in (:comments_ids)", {:comments_ids => comments_ids}]
		}

		users = ApplicationUser.find(:all, users_query_parameters);
	end

	private
	def self.comments_ids_for_comments(comments)
		comments_ids = []
		comments.each do |c|
			comments_ids << c.id
		end
		comments_ids
	end
end