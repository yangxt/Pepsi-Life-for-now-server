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

put %r{^/users/(\d+)/geolocation/?$} do
	id = params[:captures][0].to_i
	halt 403, "You can't modify a user other than yourself" unless id == @user.id
	schema = Schemas.schemas[:users_geolocation_POST]
	is_valid = Tools.validate_against_schema(schema, @json)
	halt 400, is_valid[1] unless is_valid[0]

	coordinate = Coordinate.where(:application_user_id => @user.id).first
	coordinate = Coordinate.new(:application_user => @user) unless coordinate
	coordinate.latitude = @json["coordinates"]["lat"]
	coordinate.longitude = @json["coordinates"]["long"]
	halt 500, "Couldn't create the location" unless coordinate.save
end

post %r{^/users/?$} do
	begin
		ApplicationUser.transaction do
			user = ApplicationUser.create!
			user.password = generate_password
			user.username = "username" + user.id.to_s
			user.save!

			{
				"id" => user.id,
	 			"username" => user.username,
	 			"password" => user.password
			}.to_json
		end
	rescue
		halt 500, "The user couldn't be created"
	end
end

patch %r{^/users/(\d+)/?$} do
	id = params[:captures][0].to_i
	halt 403, "You can't modify a user other than yourself" unless id == @user.id
	schema = Schemas.schemas[:users_PATCH]
	is_valid = Tools.validate_against_schema(schema, @json)
	halt 400, is_valid[1] unless is_valid[0]

	@json.each do |k, e|
		@user[k] = e
	end
	halt 500, "Couldn't patch the user" unless @user.save
end

get %r{^/users/} do
	page = params[:page].to_i
	page = 1 if page == 0
	start_page = (page - 1) * Constants::USERS_PER_PAGE

	query_parameters = {
		:limit => Constants::USERS_PER_PAGE,
		:offset => start_page,
       	:joins => "LEFT JOIN coordinates ON application_users.id = coordinates.application_user_id",
       	:select => "application_users.id, application_users.name, application_users.image_url, coordinates.latitude, coordinates.longitude",
        :group => "application_users.id, coordinates.id",
        :order => "application_users.id ASC",
        :conditions => ["application_users.id != :user", {:user => @user.id}]
	}

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
		condition = " and coordinates.latitude >= :from_lat and coordinates.latitude <= :to_lat and\
		coordinates.longitude >= :from_long and coordinates.longitude <= :to_long"
		conditions = query_parameters[:conditions]
		conditions[0] << condition
		conditions[1].merge!(bounds)
		users_count_parameters = {
			:joins => "LEFT JOIN coordinates ON application_users.id = coordinates.application_user_id",
			:conditions => conditions
		}
		puts users_count_parameters
		users_count = ApplicationUser.count(users_count_parameters)
	else
		users_count = ApplicationUser.count - 1
	end
	users = ApplicationUser.find(:all, query_parameters);

	result = {:users => [], :pages_count => ((users_count).to_f / Constants::USERS_PER_PAGE.to_f).ceil, :page => page}
	users.each do |u|
		result[:users] << {
			:id => u.id,
			:name => u.name,
			:image_url => u.image_url,
			:coordinate => {
				:latitude => u.latitude,
				:longitude => u.longitude
			}
		}
	end
	result.to_json
end

get %r{^/me/?$} do
	{
		"id" => @user.id,
		"username" => @user.username,
		"name" => @user.name,
		"seens" => @user.seens.count,
		"likes" => @user.likes.count
	}.to_json
end
