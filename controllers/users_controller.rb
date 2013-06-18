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
