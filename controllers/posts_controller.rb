require 'sinatra'
require 'sinatra/activerecord'
require './helpers/tools'
require './helpers/constants'
require './models/post'
require './models/application_user'
require './models/tag'
require './models/like'
require './models/seen'
require './models/comment'
require './schemas/posts_POST'
require './schemas/comments_POST'

post %r{^/posts/?$} do
	schema = Schemas.schemas[:posts_POST]
	is_valid = Tools.validate_against_schema(schema, @json)
	halt 400, is_valid[1] unless is_valid[0]

	tags = @json["tags"]
	@json.delete("tags")

	post = Post.new do |p|
		@json.each do |k, e|
			p[k] = e
		end
		p.application_user = @user
		p.creation_date = DateTime.now
	end
	begin
		Post.transaction do
			post.save!
			if tags
				tags.each do |e|
					Tag.create!(:text => e, :post => post)
				end
			end
		end
	rescue
		halt 500, "Couldn't create the post\n" + $!.message 
	end
	""
end

get %r{^/posts/?$} do
	page = params[:page].to_i
	page = 1 if page == 0
	start_page = (page - 1) * Constants::POSTS_PER_PAGE

	posts_query_parameters = {
		:limit => Constants::POSTS_PER_PAGE,
		:offset => start_page,
       	:joins => "LEFT JOIN application_users ON posts.application_user_id = application_users.id LEFT JOIN tags ON posts.id = tags.post_id",
       	:select => "posts.*, application_users.name as user_name, application_users.image_url as user_image_url",
        :group => "posts.id, application_users.id",
        :order => "posts.creation_date DESC",
        :conditions => ["posts.application_user_id != :user", {:user => @user.id}]
	}

	count_query_joins = "LEFT JOIN application_users ON posts.application_user_id = application_users.id"

	################################################
	#Conditions to retrieve only the posts created by friends

	only_friends = params[:only_friends] == "true"
	if only_friends
		conditions = posts_query_parameters[:conditions]
		conditions[0] << " and ((friendships.user1_id = :user and friendships.user2_id = posts.application_user_id) or (friendships.user1_id = posts.application_user_id and friendships.user2_id = :user))"
		conditions[1].merge!({:user => @user.id})
		join = " INNER JOIN friendships ON (posts.application_user_id = friendships.user1_id or posts.application_user_id = friendships.user2_id)"
		posts_query_parameters[:joins] << join
		count_query_joins << join
	end

	################################################
	#Conditions to retrieve only the posts with a specific tag
	
	tag = params[:tag]
	if tag
		conditions = posts_query_parameters[:conditions]
		conditions[0] << " and UPPER(tags.text) = UPPER(:tag)"
		conditions[1].merge!({:tag => tag})
		count_query_joins << " LEFT JOIN tags ON posts.id = tags.post_id"
	end

	################################################
	#Count the number of posts following the conditions

	###BUG HERE WITH JOINS####

	count_query_parameters = {
		:joins => count_query_joins,
		:conditions => posts_query_parameters[:conditions],
	}

	posts_count = Post.count(count_query_parameters)

	################################################
	#Get the posts following the conditions

	posts = Post.find(:all, posts_query_parameters)
	posts_ids = []
	full_posts = []
	posts.each do |p|
		full_posts << {
			:post => p
		}
		posts_ids << p.id
	end

	################################################
	#Get the tag of the retrieved posts

	tags = Post.tags_for_posts(posts)
	tags.each do |t|
		full_post = full_posts[posts_ids.index(t.post_id)]
		full_post[:tags] = full_post[:tags] || []
		full_post[:tags] << t.text
	end

	################################################
	#Get the likes count of the retrieved posts

	likes_counts = Post.likes_counts_for_posts(posts)
	likes_counts.each do |l|
		full_post = full_posts[posts_ids.index(l.post_id)]
		full_post[:likes_count] = l.count
	end

	################################################
	#Get the seens count of the retrieved posts

	seens_counts = Post.seens_counts_for_posts(posts)
	seens_counts.each do |s|
		full_post = full_posts[posts_ids.index(s.post_id)]
		full_post[:seens_count] = s.count
	end

	################################################
	#Build the response

	number_of_pages = (posts_count.to_f / Constants::POSTS_PER_PAGE.to_f).ceil
	number_of_pages = 1 if number_of_pages == 0

	result = {:posts => [], :pages_count => number_of_pages, :page => page}

	full_posts.each do |f|
		array = result[:posts]
		array << {
			:id => f[:post].id,
			:text => f[:post].text,
			:image_url => f[:post].image_url,
			:tags => f[:tags],
			:creation_date => f[:post].creation_date,
			:likes_count => f[:likes_count].to_i,
			:seens_count => f[:seens_count].to_i,
			:owner => {
				:name => f[:post].user_name,
				:image_url => f[:post].user_image_url
			}
		}
	end
	result.to_json
end

post %r{^/posts/(\d+)/likes/?$} do
	id = params[:captures][0]
	begin
		post = Post.find(id)
		Like.where(:post_id => post.id, :application_user_id => @user.id).first_or_create
	rescue ActiveRecord::RecordNotFound
		halt 404
	rescue Exceptoin => e
		halt 500, "Couldn't create like\n#{e}"
	end
	status 200
end

post %r{^/posts/(\d+)/seens/?$} do
	id = params[:captures][0]
	begin
		post = Post.find(id)
		Seen.where(:post_id => post.id, :application_user_id => @user.id).first_or_create!
	rescue ActiveRecord::RecordNotFound
		halt 404
	rescue Exception => e
		halt 500, "Couldn't create seen\n#{e}"
	end
	status 200
end

post %r{^/posts/(\d+)/comments/?$} do
	post_id = params[:captures][0]
	begin
		post = Post.find(post_id)
	rescue ActiveRecord::RecordNotFound
		halt 404
	end
	schema = Schemas.schemas[:comments_POST]
	is_valid = Tools.validate_against_schema(schema, @json)
	halt 400, is_valid[1] unless is_valid[0]

	comment = Comment.new
	comment.text = @json["text"]
	comment.application_user = @user
	comment.post = post
	comment.creation_date = DateTime.now
	halt 500, "Couldn't create the comment" unless comment.save
end

get %r{^/posts/(\d+)/comments/?$} do
	post_id = params[:captures][0]
	page = params[:page].to_i
	page = 1 if page == 0
	start_page = (page - 1) * Constants::COMMENTS_PER_PAGE
	begin
		post = Post.find(post_id)
	rescue ActiveRecord::RecordNotFound
		halt 404
	end

	result = {:comments => [], :page => page, :pages_count => (post.comments.count.to_f / Constants::COMMENTS_PER_PAGE.to_f).ceil}
	comments = post.comments.order("creation_date DESC").limit(Constants::COMMENTS_PER_PAGE).offset(start_page)
	comments.each do |c|
		array = result[:comments]
		array << {
			:id => c.id,
			:text => c.text,
			:owner => {
				:name => c.application_user.name,
				:image_url => c.application_user.image_url
			},
			:creation_date => c.creation_date
		}
	end
	result.to_json
end

get %r{^/me/posts/?$} do
	page = params[:page].to_i
	page = 1 if page == 0
	start_page = (page - 1) * Constants::POSTS_PER_PAGE

	################################################
	#Get the posts

	posts_query_parameters = {
		:limit => Constants::POSTS_PER_PAGE,
		:offset => start_page,
       	:select => "posts.*",
        :order => "posts.creation_date DESC",
        :conditions => ["posts.application_user_id = :user", {:user => @user.id}]
	}

	posts = Post.find(:all, posts_query_parameters)
	posts_ids = []
	full_posts = []
	posts.each do |p|
		full_posts << {
			:post => p
		}
		posts_ids << p.id
	end

	################################################
	#Get the tag of the retrieved posts

	tags = Post.tags_for_posts(posts)
	tags.each do |t|
		full_post = full_posts[posts_ids.index(t.post_id)]
		full_post[:tags] = full_post[:tags] || []
		full_post[:tags] << t.text
	end

	################################################
	#Get the likes count of the retrieved posts

	likes_counts = Post.likes_counts_for_posts(posts)
	likes_counts.each do |l|
		full_post = full_posts[posts_ids.index(l.post_id)]
		full_post[:likes_count] = l.count
	end

	################################################
	#Get the seens count of the retrieved posts

	seens_counts = Post.seens_counts_for_posts(posts)
	seens_counts.each do |s|
		full_post = full_posts[posts_ids.index(s.post_id)]
		full_post[:seens_count] = s.count
	end

	################################################
	#Build the response

	number_of_pages = (@user.posts.count.to_f / Constants::POSTS_PER_PAGE.to_f).ceil
	number_of_pages = 1 if number_of_pages == 0
	result = {:posts => [], :pages_count => number_of_pages, :page => page}

	full_posts.each do |f|
		array = result[:posts]
		array << {
			:id => f[:post].id,
			:text => f[:post].text,
			:image_url => f[:post].image_url,
			:tags => f[:tags],
			:creation_date => f[:post].creation_date,
			:likes_count => f[:likes_count].to_i,
			:seens_count => f[:seens_count].to_i,
		}
	end
	result.to_json
end