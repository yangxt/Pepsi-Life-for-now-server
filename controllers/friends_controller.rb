require 'sinatra'
require 'sinatra/activerecord'
require './helpers/tools'
require './models/application_user'
require './models/friendship'
require './schemas/friends_POST'

post %r{^/me/friends/?$} do
	schema = Schemas.schemas[:friends_POST]
	is_valid = Tools.validate_against_schema(schema, @json)
	halt 400, is_valid[1] unless is_valid[0]

	friend_id = @json["friend"].to_i
	begin
		friend = ApplicationUser.find(friend_id)
	rescue ActiveRecord::RecordNotFound
		halt 404
	end

	halt 400, "You can't be your own friend" if friend == @user

	friendship = Friendship.where(["(user1_id = :user and user2_id = :friend) or (user1_id = :friend and user2_id = :user)", {:user => @user.id, :friend => friend.id}]).first
	if !friendship
		halt 500, "Couldn't add the user as a friend" unless Friendship.create(:user1 => @user, :user2 => friend)
	end

	result = {
		"friend_url" => "me/friends/" + friend_id.to_s + "/"
	}
	body result.to_json
	status 200
end

get %r{^/me/friends/?$} do
	bounds = {
		:from_lat => params[:from_lat],
		:to_lat => params[:to_lat],
		:from_long => params[:from_long],
		:to_long => params[:to_long]
	}

	all_bounds_provided = true
	bounds.each_value do |v|
		if !v
			all_bounds_provided = false;
			break
		end
	end
	if all_bounds_provided
		friends = @user.friends_in_bounds(bounds)
	else
		friends = @user.friends
	end

	results = {:friends => []}
	friends.each do |f|
		friend = {
			:id => f.id,
			:name => f.name,
			:image_url => f.image_url,
		}
		if f.latitude && f.longitude
			friend[:coordinate] = {
				:latitude => f.latitude.to_f,
				:longitude => f.longitude.to_f
			}
		else
			friend[:coordinate] = "null"
		end
		results[:friends] << friend
	end
	body results.to_json
	status 200
end

get %r{^/me/friends/(\d+)/posts/?$} do
	friend_id = params[:captures][0]
	friend = @user.friend_by_id(friend_id)
	halt 404 unless friend

	last_id = params[:last_id].to_i if params[:last_id] 

	################################################
	#Get the posts

	posts = Post.limit(Constants::POSTS_PER_PAGE).order("posts.id DESC").where(["application_user_id = :friend_id and posts.id < :last_id", {:friend_id => friend_id, :last_id => last_id}])
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

	result = {:posts => []}

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
	body result.to_json
	status 200
end

