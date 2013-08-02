 # -*- coding: utf-8 -*-
require 'sinatra'
require 'sinatra/activerecord'
require './helpers/tools'
require './models/application_user'
require './models/friendship'
require './schemas/friends_POST'

post %r{^/me/friends/?$} do
	schema = Schemas.schemas[:friends_POST]
	is_valid = Tools.validate_against_schema(schema, @json)
	haltJsonp 400, is_valid[1] unless is_valid[0]

	friend_id = @json["friend"].to_i
	begin
		friend = ApplicationUser.find(friend_id)
	rescue ActiveRecord::RecordNotFound
		haltJsonp 404
	end

	haltJsonp 400, "You can't be your own friend" if friend == @user

	friendship = Friendship.where(["(user1_id = :user and user2_id = :friend) or (user1_id = :friend and user2_id = :user)", {:user => @user.id, :friend => friend.id}]).first
	if !friendship
		haltJsonp 500, "Couldn't add the user as a friend" unless Friendship.create(:user1 => @user, :user2 => friend)
	end

	jsonp({:status => 200, :body => {}})
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

	################################################
	#Get the posts following the conditions

	friends_ids = []
	full_friends = []
	friends.each do |f|
		full_friends << {
			:friend => f,
			:posts_count => 0
		}
		friends_ids << f.id
	end

	################################################
	#Get the posts count

	posts_counts = ApplicationUser.posts_counts_for_users(friends)
	posts_counts.each do |p|
		full_friend = full_friends[friends_ids.index(p.application_user_id)]
		full_friend[:posts_count] = p.count
	end

	################################################
	#Retrieve likes count for each user

	likes_counts = ApplicationUser.likes_counts_for_users(friends)
	likes_counts.each do |l|
		full_friend = full_friends[friends_ids.index(l.application_user_id)]
		full_friend[:likes_count] = l.count
	end

	################################################
	#Retrieve seens count for each friend

	seens_counts = ApplicationUser.seens_counts_for_users(friends)
	seens_counts.each do |l|
		full_friend = full_friends[friends_ids.index(l.application_user_id)]
		full_friend[:seens_count] = l.count
	end

	################################################

	results = {:friends => []}
	full_friends.each do |f|
		friend = {
			:id => f[:friend].id,
			:name => f[:friend].name,
			:image_url => f[:friend].image_url,
			:description => f[:friend].description,
			:posts_count => f[:posts_count].to_i,
			:likes_count => f[:likes_count].to_i,
			:seens_count => f[:seens_count].to_i
		}
		if f[:friend].latitude && f[:friend].longitude
			friend[:coordinate] = {
				:latitude => f[:friend].latitude.to_f,
				:longitude => f[:friend].longitude.to_f
			}
		else
			friend[:coordinate] = "null"
		end
		results[:friends] << friend
	end
	jsonp({:status => 200, :body => results})
end


