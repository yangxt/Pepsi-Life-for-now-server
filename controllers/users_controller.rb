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
			body result.to_json
			status 200
		end
	rescue Exception=>e
		halt 500, "The user couldn't be created\n#{e}"
	end
end

get %r{^/users/?$} do
	last_id = params[:last_id].to_i if params[:last_id] 

	users_query_parameters = {
		:limit => Constants::USERS_PER_PAGE,
       	:joins => "LEFT JOIN coordinates ON application_users.id = coordinates.application_user_id",
       	:select => "application_users.id, application_users.name, application_users.image_url, coordinates.latitude, coordinates.longitude, coordinates.id as coordinates_id",
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
	users.each do |u|
		users_ids << u.id
	end

	################################################
	#Retrieve likes count for each user

	likes_query_parameters = {
		:joins => "LEFT JOIN likes ON likes.application_user_id = application_users.id",
       	:select => "count(likes.id) as count",
        :group => "application_users.id",
        :order => "application_users.id ASC",
        :conditions => ["application_users.id in (:users_ids)", {:users_ids => users_ids}]
	}

	likes_counts = ApplicationUser.find(:all, likes_query_parameters)

	################################################
	#Retrieve seens count for each user

	seens_query_parameters = {
		:joins => "LEFT JOIN seens ON seens.application_user_id = application_users.id",
       	:select => "count(seens.id) as count",
        :group => "application_users.id",
        :order => "application_users.id ASC",
        :conditions => ["application_users.id in (:users_ids)", {:users_ids => users_ids}]
	}

	seens_counts = ApplicationUser.find(:all, seens_query_parameters)

	################################################
	#Build the response

	result = {:users => []}
	friends = @user.friends
	users.each_with_index do |u, i|
		user = {
			:id => u.id,
			:name => u.name,
			:image_url => u.image_url,
			:friend => friends.include?(u),
			:seens_count => seens_counts[i].count.to_i,
			:likes_count => likes_counts[i].count.to_i
		}
		if u.coordinates_id
			user[:coordinate] = {
				:latitude => u.latitude.to_f,
				:longitude => u.longitude.to_f
			}
		else
			user[:coordinate] = "null"
		end
		result[:users] << user
	end
	body result.to_json
	status 200
end

get %r{^/me/?$} do
	result =  {
		"id" => @user.id,
		"username" => @user.username,
		"name" => @user.name,
		"seens_count" => @user.seens.count,
		"likes_count" => @user.likes.count
	}
	body result.to_json
	status 200
end

put %r{^/me/geolocation/?$} do
	schema = Schemas.schemas[:users_geolocation_POST]
	is_valid = Tools.validate_against_schema(schema, @json)
	halt 400, is_valid[1] unless is_valid[0]

	coordinate = Coordinate.where(:application_user_id => @user.id).first_or_create
	coordinate.latitude = @json["coordinates"]["lat"]
	coordinate.longitude = @json["coordinates"]["long"]
	halt 500, "Couldn't create the location" unless coordinate.save
	body "{}"
	status 200
end

patch %r{^/me/?$} do
	schema = Schemas.schemas[:users_PATCH]
	is_valid = Tools.validate_against_schema(schema, @json)
	halt 400, is_valid[1] unless is_valid[0]

	@json.each do |k, e|
		@user[k] = e
	end
	halt 500, "Couldn't patch the user" unless @user.save
	body "{}"
	status 200
end

