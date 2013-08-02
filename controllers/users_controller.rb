 # -*- coding: utf-8 -*-
require 'sinatra'
require 'sinatra/activerecord'
require './models/application_user'
require './models/coordinate'
require './schemas/users_geolocation_POST'
require './schemas/users_PATCH'

def generate_password
	chars = 'ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz1234567890'
	string_length = 14
	password = ''
	index_array = (0...chars.length).to_a

	i = 0
	while i < string_length
		index = index_array.sample
		password << chars[index]
		i += 1
	end
	password
end

post %r{^/users/?$} do
	begin
		ApplicationUser.transaction do
			user = ApplicationUser.create!
			user.password = generate_password
			user.username = "username" + user.id.to_s
			user.save!

			result = {
				"id" => user.id,
	 			"username" => user.username,
	 			"password" => user.password
			}
			jsonp({:status => 200, :body => result})
		end
	rescue Exception=>e
		haltJsonp 500, "The user couldn't be created\n#{e}"
	end
end

get %r{^/users/?$} do
	last_id = params[:last_id].to_i if params[:last_id] 

	users_query_parameters = {
		:limit => Constants::USERS_PER_PAGE,
       	:joins => "LEFT JOIN coordinates ON application_users.id = coordinates.application_user_id",
       	:select => "application_users.id, application_users.name, application_users.description, application_users.image_url, coordinates.latitude, coordinates.longitude, coordinates.id as coordinates_id",
        :group => "application_users.id, coordinates.id",
        :order => "application_users.id DESC",
        :conditions => ["application_users.id != :user", {:user => @user.id}]
	}

	if last_id
		conditions = users_query_parameters[:conditions]
		conditions[0] << " and application_users.id < :last_id"
		conditions[1][:last_id] = last_id
	end

	################################################
	#Conditions to select users bounded to coordinate

	coordinate_bounds = {
		:from_lat => params[:from_lat],
		:to_lat => params[:to_lat],
		:from_long => params[:from_long],
		:to_long => params[:to_long]
	}

	coordinate_bounds_provided = true

	coordinate_bounds.each_value do |v|
		if !v
			coordinate_bounds_provided = false;
			break
		end
	end

	if coordinate_bounds_provided
		condition = " and coordinates.latitude >= :from_lat and coordinates.latitude <= :to_lat and\
		coordinates.longitude >= :from_long and coordinates.longitude <= :to_long"
		conditions = users_query_parameters[:conditions]
		conditions[0] << condition
		conditions[1].merge!(coordinate_bounds)
	end

	################################################

	users = ApplicationUser.find(:all, users_query_parameters)
	users_ids = []
	full_users = []
	users.each do |u|
		full_users << {
			:user => u,
			:likes_count => 0,
			:seens_count => 0,
			:posts_count => 0
		}
		users_ids << u.id
	end

	################################################
	#Retrieve posts count for each user

	posts_counts = ApplicationUser.posts_counts_for_users(users)
	posts_counts.each do |l|
		full_user = full_users[users_ids.index(l.application_user_id)]
		full_user[:posts_count] = l.count
	end

	################################################
	#Retrieve likes count for each user

	likes_counts = ApplicationUser.likes_counts_for_users(users)
	likes_counts.each do |l|
		full_user = full_users[users_ids.index(l.application_user_id)]
		full_user[:likes_count] = l.count
	end

	################################################
	#Retrieve seens count for each user

	seens_counts = ApplicationUser.seens_counts_for_users(users)
	seens_counts.each do |l|
		full_user = full_users[users_ids.index(l.application_user_id)]
		full_user[:seens_count] = l.count
	end

	################################################
	#Build the response

	result = {:users => []}
	friends = @user.friends
	full_users.each_with_index do |u|
		user = {
			:id => u[:user].id,
			:name => u[:user].name,
			:image_url => u[:user].image_url,
			:friend => friends.include?(u[:user]),
			:seens_count => u[:seens_count].to_i,
			:likes_count => u[:likes_count].to_i,
			:posts_count => u[:posts_count].to_i,
			:description => u[:user].description
		}
		if u[:user].coordinates_id
			user[:coordinate] = {
				:latitude => u[:user].latitude.to_f,
				:longitude => u[:user].longitude.to_f
			}
		else
			user[:coordinate] = "null"
		end
		result[:users] << user
	end
	jsonp({:status => 200, :body => result})
end

get %r{^/users/(\d+)/posts/?$} do
	user_id = params[:captures][0]
	user = ApplicationUser.where(:id => user_id).first
	haltJsonp 404 unless user

	last_id = params[:last_id].to_i if params[:last_id] 

	################################################
	#Get the posts

	conditions = ["application_user_id = :user_id", {:user_id => user_id}]

	if last_id
		conditions[0] << " and posts.id < :last_id"
		conditions[1][:last_id] = last_id
	end

	posts = Post.limit(Constants::POSTS_PER_PAGE).order("posts.id DESC").where(conditions)
	posts_ids = []
	full_posts = []
	posts.each do |p|
		full_posts << {
			:post => p,
			:likes_count => 0,
			:seens_count => 0,
			:comments_count => 0
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
	#Get the comments count of the retrieved posts

	comments_count = Post.comments_counts_for_posts(posts)
	comments_count.each do |s|
		full_post = full_posts[posts_ids.index(s.post_id)]
		full_post[:comments_count] = s.count
	end

	################################################
	#Get seens posts

	posts = Post.seen_posts_for_user(@user)
	full_posts.each do |f|
		if (posts.include?(f[:post]))
			f[:seen] = true
		else
			f[:seen] = false
		end
	end

	################################################
	#Get liked posts

	posts = Post.liked_posts_for_user(@user)
	full_posts.each do |f|
		if (posts.include?(f[:post]))
			f[:liked] = true
		else
			f[:liked] = false
		end
	end

	################################################
	#Build the response

	result = {:posts => [], :posts_count => user.posts.count, :likes_count => user.likes.count}

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
			:comments_count => f[:comments_count].to_i,
			:liked => f[:liked],
			:seen => f[:seen]
		}
	end
	jsonp({:status => 200, :body => result})
end

get %r{^/me/?$} do
	result =  {
		"id" => @user.id,
		"username" => @user.username,
		"name" => @user.name,
		"seens_count" => @user.seens.count,
		"likes_count" => @user.likes.count,
		"posts_count" => @user.posts.count,
		"description" => @user.description,
		"image_url" => @user.image_url,
	}
	jsonp({:status => 200, :body => result})
end

put %r{^/me/geolocation/?$} do
	schema = Schemas.schemas[:users_geolocation_POST]
	is_valid = Tools.validate_against_schema(schema, @json)
	haltJsonp 400, is_valid[1] unless is_valid[0]

	coordinate = Coordinate.where(:application_user_id => @user.id).first
	coordinate = Coordinate.new(:application_user_id => @user.id) unless coordinate
	coordinate.latitude = @json["coordinates"]["lat"]
	coordinate.longitude = @json["coordinates"]["long"]
	haltJsonp 500, "Couldn't create the location" unless coordinate.save
	jsonp({:status => 200, :body => {}})
end

patch %r{^/me/?$} do
	schema = Schemas.schemas[:users_PATCH]
	is_valid = Tools.validate_against_schema(schema, @json)
	haltJsonp 400, is_valid[1] unless is_valid[0]

	@json.each do |k, e|
		@user[k] = e
	end
	haltJsonp 500, "Couldn't patch the user" unless @user.save
	jsonp({:status => 200, :body => {}})
end

