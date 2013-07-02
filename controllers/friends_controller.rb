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

	{
		"friend_url" => "me/friends/" + friend_id.to_s + "/"
	}.to_json
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
			:name => f.name,
			:image_url => f.image_url,
			:coordinate => {
				:latitude => f.latitude,
				:longitude => f.longitude
			}
		}
		results[:friends] << friend
	end
	results.to_json
end